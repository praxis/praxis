# frozen_string_literal: true

# A resource creates a data store and instantiates a list of models that it wishes to load, building up the overall set of data that it will need.
# Once that is complete, the data set is iterated and a resultant view is generated.
module Praxis
  module Mapper
    class ResourceNotFound < RuntimeError
      attr_reader :type, :id

      def initialize(type:, id: nil)
        @type = type
        @id = id
      end
    end

    class Resource
      extend Praxis::Finalizable

      attr_accessor :record

      @properties = {}

      class << self
        attr_reader :model_map, :properties
        # Names of the memoizable things (without the @__ prefix)
        attr_accessor :memoized_variables
      end

      # TODO: also support an attribute of sorts on the versioned resource module. ie, V1::Resources.api_version.
      #       replacing the self.superclass == Praxis::Mapper::Resource condition below.
      def self.inherited(klass)
        super

        klass.instance_eval do
          # It is expected that each versioned set of resources
          # will have a common Base class, and so should share
          # a model_map
          @model_map = if superclass == Praxis::Mapper::Resource
                         {}
                       else
                         superclass.model_map
                       end

          @properties = superclass.properties.clone
          @_filters_map = {}
          @memoized_variables = []
        end
      end

      # TODO: Take symbol/string and resolve the klass (but lazily, so we don't care about load order)
      def self.model(klass = nil)
        if klass
          raise "Model #{klass.name} must be compatible with Praxis. Use ActiveModelCompat or similar compatability plugin." unless klass.methods.include?(:_praxis_associations)

          @model = klass
          model_map[klass] = self
        else
          @model
        end
      end

      def self.property(name, dependencies: nil, through: nil)
        properties[name] = { dependencies: dependencies, through: through }
      end

      def self._finalize!
        finalize_resource_delegates
        define_model_accessors

        hookup_callbacks
        super
      end

      def self.finalize_resource_delegates
        return unless @resource_delegates

        @resource_delegates.each do |record_name, record_attributes|
          record_attributes.each do |record_attribute|
            define_resource_delegate(record_name, record_attribute)
          end
        end
      end

      def self.define_model_accessors
        return if model.nil?

        model._praxis_associations.each do |k, v|
          define_model_association_accessor(k, v) unless instance_methods.include? k
        end
      end

      def self.hookup_callbacks
        return unless ancestors.include?(Praxis::Mapper::Resources::Callbacks)

        affected_methods = (before_callbacks.keys + after_callbacks.keys + around_callbacks.keys).uniq
        # TODO!! Only create 1 prepended module for all methods!!!
        instance_module = nil
        class_module = nil
        affected_methods&.each do |method|
          calls = {}
          calls[:before] = before_callbacks[method] if before_callbacks.key?(method)
          calls[:around] = around_callbacks[method] if around_callbacks.key?(method)
          calls[:after] = after_callbacks[method] if after_callbacks.key?(method)

          if method.start_with?('self.')
            # Look for a Class method
            simple_name = method.to_s.gsub(/^self./, '').to_sym
            raise "Error building callback: Method #{method} is not defined in class #{name}" unless methods.include?(simple_name)

            class_module ||= Module.new
            has_args = method(simple_name).parameters.any? { |(type, _)| %i[req opt rest].include?(type) }
            has_kwargs = method(simple_name).parameters.any? { |(type, _)| %i[keyreq keyrest].include?(type) }

            create_override_module(mod: class_module, method: simple_name, calls: calls, has_args: has_args, has_kwargs: has_kwargs)
          else
            # Look for an instance method
            raise "Error building callback: Method #{method} is not defined in class #{name}" unless method_defined?(method)

            instance_module ||= Module.new
            has_args = instance_method(method).parameters.any? { |(type, _)| %i[req opt rest].include?(type) }
            has_kwargs = instance_method(method).parameters.any? { |(argtype, _)| %i[keyreq keyrest].include?(argtype) }

            create_override_module(mod: instance_module, method: method, calls: calls, has_args: has_args, has_kwargs: has_kwargs)
          end
        end
        # Prepend the created instance and/or class modules if there were any functions in them
        prepend instance_module if instance_module
        singleton_class.send(:prepend, class_module) if class_module
      end

      def self.for_record(record)
        return record._resource if record._resource

        if (resource_class_for_record = model_map[record.class])
          record._resource = resource_class_for_record.new(record)
        else
          version = name.split('::')[0..-2].join('::')
          resource_name = record.class.name.split('::').last

          raise "No resource class corresponding to the model class '#{record.class}' is defined. (Did you forget to define '#{version}::#{resource_name}'?)"
        end
      end

      def self.wrap(records)
        if records.nil?
          []
        elsif records.is_a?(Enumerable)
          records.compact.map { |record| for_record(record) }
        elsif records.respond_to?(:to_a)
          records.to_a.compact.map { |record| for_record(record) }
        else
          for_record(records)
        end
      end

      # OVERRIDEN FOR NOW!!!
      def self.get(condition)
        record = model.get(condition)

        wrap(record)
      end

      def self.all(condition = {})
        records = model.all(condition)

        wrap(records)
      end

      def self.resource_delegates
        @resource_delegates ||= {}
      end

      def self.resource_delegate(spec)
        spec.each do |resource_name, attributes|
          resource_delegates[resource_name] = attributes
        end
      end

      # Defines wrappers for model associations that return Resources
      def self.define_model_association_accessor(name, association_spec)
        association_model = association_spec.fetch(:model)
        association_resource_class = model_map[association_model]

        return unless association_resource_class

        memoized_variables << name
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          return @__#{name} if instance_variable_defined?("@__#{name}")

          records = record.#{name}
          return nil if records.nil?
          @__#{name} ||= #{association_resource_class}.wrap(records)
        end
        RUBY
      end

      def self.define_resource_delegate(resource_name, resource_attribute)
        related_model = model._praxis_associations[resource_name][:model]
        related_association = related_model._praxis_associations[resource_attribute]

        if related_association
          define_delegation_for_related_association(resource_name, resource_attribute, related_association)
        else
          define_delegation_for_related_attribute(resource_name, resource_attribute)
        end
      end

      def self.define_delegation_for_related_attribute(resource_name, resource_attribute)
        memoized_variables << resource_attribute
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{resource_attribute}
          @__#{resource_attribute} ||= if (rec = self.#{resource_name})
          rec.#{resource_attribute}
            end
        end
        RUBY
      end

      def self.define_delegation_for_related_association(resource_name, resource_attribute, related_association)
        related_resource_class = model_map[related_association[:model]]
        return unless related_resource_class

        memoized_variables << resource_attribute
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{resource_attribute}
          @__#{resource_attribute} ||= if (rec = self.#{resource_name})
          if (related = rec.#{resource_attribute})
            #{related_resource_class.name}.wrap(related)
          end
        end
      end
        RUBY
      end

      def self.define_accessor(name)
        ivar_name = if name.to_s =~ /\?/
                      "is_#{name.to_s[0..-2]}"
                    elsif name.to_s =~ /!/
                      "#{name.to_s[0..-2]}_bang"
                    else
                      name.to_s
                    end
        memoized_variables << ivar_name
        module_eval <<-RUBY, __FILE__, __LINE__ + 1
      def #{name}
        return @__#{ivar_name} if instance_variable_defined?("@__#{ivar_name}")
        @__#{ivar_name} = record.#{name}
      end
        RUBY
      end

      # TODO: this shouldn't be needed if we incorporate it with the properties of the mapper...
      # ...maybe what this means is that we can change it for a better DSL in the resource?
      def self.filters_mapping(definition = {})
        @_filters_map = \
          case definition
          when Hash
            definition
          when Array
            definition.each_with_object({}) { |item, hash| hash[item.to_sym] = item }
          else
            raise 'Resource.filters_mapping only allows a hash or an array'
          end
      end

      def self.craft_filter_query(base_query, filters:)
        if filters
          raise "To use API filtering, you must define the mapping of api-names to resource properties (using the `filters_mapping` method in #{self})" unless @_filters_map

          debug = Praxis::Application.instance.config.mapper.debug_queries
          base_query = model._filter_query_builder_class.new(query: base_query, model: model, filters_map: @_filters_map, debug: debug).generate(filters)
        end

        base_query
      end

      def self.craft_field_selection_query(base_query, selectors:)
        if selectors && model._field_selector_query_builder_class
          debug = Praxis::Application.instance.config.mapper.debug_queries
          base_query = model._field_selector_query_builder_class.new(query: base_query, selectors: selectors, debug: debug).generate
        end

        base_query
      end

      def self.craft_pagination_query(base_query, pagination:)
        handler_klass = model._pagination_query_builder_class
        return base_query unless handler_klass && (pagination.paginator || pagination.order)

        # Gather and save the count if required
        pagination.total_count = handler_klass.count(base_query.dup) if pagination.paginator&.total_count

        base_query = handler_klass.order(base_query, pagination.order)
        handler_klass.paginate(base_query, pagination)
      end

      def initialize(record)
        @record = record
      end

      def reload
        clear_memoization
        reload_record
        self
      end

      def clear_memoization
        self.class.memoized_variables.each do |name|
          ivar = "@__#{name}"
          remove_instance_variable(ivar) if instance_variable_defined?(ivar)
        end
      end

      def reload_record
        record.reload
      end

      def respond_to_missing?(name, *)
        @record.respond_to?(name) || super
      end

      def method_missing(name, *args)
        if @record.respond_to?(name)
          self.class.define_accessor(name)
          send(name)
        else
          super
        end
      end

      # Defines a 'proxy' method in the given module (mod), so it can then be prepended
      # There are mostly 3 flavors, which dictate how to define the procs (to make sure we play nicely
      # with ruby's arguments and all). Method with only args, with only kwords, and with both
      # Note: if procs could be defined with the (...) syntax, this could be more DRY and simple...
      def self.create_override_module(mod:, method:, calls:, has_args:, has_kwargs:)
        mod.class_eval do
          if has_args && has_kwargs
            # Setup the method to take both args and  kwargs
            define_method(method) do |*args, **kwargs|
              calls[:before]&.each do |target|
                target.is_a?(Symbol) ? send(target, *args, **kwargs) : instance_exec(*args, **kwargs, &target)
              end

              orig_call = proc { |*a, **kw| super(*a, **kw) }
              around_chain = calls[:around].inject(orig_call) do |inner, target|
                proc { |*a, **kw| send(target, *a, **kw, &inner) }
              end
              result = if calls[:around].presence
                         around_chain.call(*args, **kwargs)
                       else
                         super(*args, **kwargs)
                       end
              calls[:after]&.each do |target|
                target.is_a?(Symbol) ? send(target, *args, **kwargs) : instance_exec(*args, **kwargs, &target)
              end
              result
            end
          elsif has_kwargs && !has_args
            # Setup the method to only take kwargs
            define_method(method) do |**kwargs|
              calls[:before]&.each do |target|
                target.is_a?(Symbol) ? send(target, **kwargs) : instance_exec(**kwargs, &target)
              end
              orig_call = proc { |**kw| super(**kw) }
              around_chain = calls[:around].inject(orig_call) do |inner, target|
                proc { |**kw| send(target, **kw, &inner) }
              end
              result = if calls[:around].presence
                         around_chain.call(**kwargs)
                       else
                         super(**kwargs)
                       end
              calls[:after]&.each do |target|
                target.is_a?(Symbol) ? send(target, **kwargs) : instance_exec(**kwargs, &target)
              end
              result
            end
          else
            # Setup the method to only take args
            define_method(method) do |*args|
              calls[:before]&.each do |target|
                target.is_a?(Symbol) ? send(target, *args) : instance_exec(*args, &target)
              end
              orig_call = proc { |*a| super(*a) }
              around_chain = calls[:around].inject(orig_call) do |inner, target|
                proc { |*a| send(target, *a, &inner) }
              end
              result = if calls[:around].presence
                         around_chain.call(*args)
                       else
                         super(*args)
                       end
              calls[:after]&.each do |target|
                target.is_a?(Symbol) ? send(target, *args) : instance_exec(*args, &target)
              end
              result
            end
          end
        end
      end
      private_class_method :create_override_module
    end
  end
end
