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

    # Simple Object that will respond to a set of methods, by simply delegating to the target (will also delegate _resource)
    class ForwardingStruct
      extend Forwardable
      attr_accessor :target

      def self.for(names)
        Class.new(self) do
          names.each do |(orig, forwarded)|
            def_delegator :@target, forwarded, orig
          end
          def_delegator :@target, :_resource
        end
      end

      def initialize(target)
        @target = target
      end
    end

    class Resource
      extend Praxis::Finalizable

      attr_accessor :record

      @properties = {}
      @property_groups = {}
      @cached_forwarders = {}

      class << self
        attr_reader :model_map, :properties, :property_groups, :cached_forwarders
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
          @property_groups = superclass.property_groups.clone
          @cached_forwarders = superclass.cached_forwarders.clone
          @registered_batch_computations = {} # hash of attribute_name -> {proc: , with_instance_method: }
          @_filters_map = {}
          @_order_map = {}
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

      # The `as:` can be used for properties that correspond to an underlying association of a different name. With this, the selector generator, is able to
      # follow and pass any incoming nested fields when necessary (as opposed to only add dependencies and discard nested fields)
      # No dependencies are allowed to be defined if `as:` is used (as the dependencies should be defined at the final aliased property)
      def self.property(name, dependencies: nil, as: nil) # rubocop:disable Naming/MethodParameterName
        h = { dependencies: dependencies }
        if as
          raise 'Cannot use dependencies for a property when using the "as:" keyword' if dependencies.presence

          h.merge!({ as: as })
        end
        properties[name] = h
      end

      # Saves the name of the group, and the associated mediatype where the group attributes are defined at
      def self.property_group(name, media_type)
        property_groups[name] = media_type
      end

      def self.batch_computed(attribute, with_instance_method: true, &block)
        raise "This resource (#{name})is already finalized. Defining batch_computed attributes needs to be done before finalization" if @finalized
        raise 'It is necessary to pass a block when using the batch_computed method' unless block_given?

        required_params = block.parameters.select { |t, _n| t == :keyreq }.map { |_a, b| b }.uniq
        raise 'The block for batch_computed can only accept one required kw param named :rows_by_id' unless required_params == [:rows_by_id]

        @registered_batch_computations[attribute.to_sym] = { proc: block.to_proc, with_instance_method: with_instance_method }
      end

      def self.batched_attributes
        @registered_batch_computations.keys
      end

      def self._finalize!
        validate_properties
        finalize_resource_delegates
        define_batch_processors
        define_model_accessors
        define_property_groups

        hookup_callbacks
        super
      end

      def self.validate_properties
        # Disabled for now
        # errors = detect_invalid_properties
        # raise errors unless errors.empty?
      end

      # Verifies if the system has badly defined properties
      # For example, properties that correspond to an underlying association method (for which there is no
      # overriden method in the resource) must not have dependencies defined, as it is clear the association is the only one
      def self.detect_invalid_properties
        return unless !model.nil? && model.respond_to?(:_praxis_associations)

        invalid = {}
        existing_associations = model._praxis_associations.keys
        properties.slice(*existing_associations).each do |prop_name, data|
          # If we have overriden the assoc with our own method, we allow you to define deps (or as: aliases)
          next if instance_methods.include? prop_name

          example_def = "property #{prop_name}"
          example_def.concat("dependencies: #{data[:dependencies]}") if data[:dependencies].presence
          example_def.concat("as: #{data[:as]}") if data[:as].presence
          # If we haven't overriden the method, we'll create an accessor, so defining deps does not make sense
          error = "Error defining property '#{prop_name}' in resource #{name}. Method #{prop_name} is already an association " \
                  "which will be properly wrapped with an accessor, so you do not need to define it as a property.\n" \
                  'Only define properties for methods that you override in the resource, as a way to specify which dependencies ' \
                  "that requires to use inside it\n" \
                  "Current definition looks like: #{example_def}"
          invalid[prop_name] = error
        end
        invalid
      end

      def self.define_batch_processors
        return unless @registered_batch_computations.presence

        const_set(:BatchProcessors, Module.new)
        @registered_batch_computations.each do |name, opts|
          self::BatchProcessors.module_eval do
            define_singleton_method(name, opts[:proc])
          end
          next unless opts[:with_instance_method]

          # Define the instance method for it to call the batch processor...passing its 'id' and value
          # This can be turned off by setting :with_instance_method, in case the 'id' of a resource
          # it is not called 'id' (simply define an instance method similar to this one below)
          define_method(name) do
            self.class::BatchProcessors.send(name, rows_by_id: { id => self })[id]
          end
        end
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

        define_aliased_methods

        model._praxis_associations.each do |k, v|
          define_model_association_accessor(k, v) unless instance_methods.include? k
        end
      end

      def self.validate_associations_path(model, path)
          first, *rest = path

        assoc = model._praxis_associations[first]
        return first unless assoc

        rest.presence ? validate_associations_path(assoc[:model], rest) : nil
      end

      def self.define_aliased_methods
        with_different_alias_name = properties.reject { |name, opts| name == opts[:as] || opts[:as].nil? }

        with_different_alias_name.each do |prop_name, opts|
          next if instance_methods.include? prop_name
          # Check that the as: symbol, or each of the dotten notation names are pure association names in the corresponding resources, aliases aren't supported"
          unless opts[:as] == :self
            raise "No!!!" unless self.model&.respond_to?(:_praxis_associations)

            errors = validate_associations_path(model, opts[:as].to_s.split('.').map(&:to_sym))
            if errors.presence
              require 'pry'
              binding.pry
              raise "INVALID PATH #{errors}" 
            end
          end

          # Straight call to another association method (that we will generate automatically in our association accessors)
          module_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{prop_name}
              #{opts[:as]}
            end
          RUBY
        end
      end

      # Defines the dependencies and the method of a property group
      # The dependencies are going to be defined as the methods that wrap the group's attributes i.e., 'group_attribute1'
      # The method defined will return a ForwardingStruct object instance, that will simply define a method name for each existing property
      # which simply calls the underlying 'group name' prefixed methods on the original object
      # For example: if we have a group named 'grouping', which has 'name' and 'phone' attributes defined.
      # - the property dependencies will be defined as: property :grouping, dependencies: [:name, :phone]
      # - the 'grouping' method will return an instance object, that will respond to 'name' (and forward to 'grouping_name') and to 'phone'
      #   (and forward to 'grouping_phone')
      def self.define_property_groups
        property_groups.each do |(name, media_type)|
          # Set a property for their dependencies using the "group"_"attribute"
          prefixed_property_deps = media_type.attribute.attributes[name].type.attributes.keys.each_with_object({}) do |key, hash|
            hash[key] = "#{name}_#{key}".to_sym
          end
          property name, dependencies: prefixed_property_deps.values
          @cached_forwarders[name] = ForwardingStruct.for(prefixed_property_deps)

          define_method(name) do
            self.class.cached_forwarders[name].new(self)
          end
        end
      end

      def self.hookup_callbacks
        return unless ancestors.include?(Praxis::Mapper::Resources::Callbacks)

        instance_module = nil
        class_module = nil

        affected_methods = (before_callbacks.keys + after_callbacks.keys + around_callbacks.keys).uniq
        affected_methods&.each do |method|
          calls = {}
          calls[:before] = before_callbacks[method] if before_callbacks.key?(method)
          calls[:around] = around_callbacks[method] if around_callbacks.key?(method)
          calls[:after] = after_callbacks[method] if after_callbacks.key?(method)

          if method.start_with?('self.')
            # Look for a Class method
            simple_name = method.to_s.gsub(/^self./, '').to_sym
            raise "Error building callback: Class-level method #{method} is not defined in class #{name}" unless methods.include?(simple_name)

            class_module ||= Module.new
            create_override_module(mod: class_module, method: method(simple_name), calls: calls)
          else
            # Look for an instance method
            raise "Error building callback: Instance method #{method} is not defined in class #{name}" unless method_defined?(method)

            instance_module ||= Module.new
            create_override_module(mod: instance_module, method: instance_method(method), calls: calls)
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

        association_resource_class_name = "::#{association_resource_class}" # Ensure we point at classes globally
        memoized_variables << name

        # Add the call to wrap (for true collections) or simply for_record if it's a n:1 association
        wrapping = \
          case association_spec.fetch(:type)
          when :one_to_many, :many_to_many
            "@__#{name} ||= #{association_resource_class_name}.wrap(records)"
          else
            "@__#{name} ||= #{association_resource_class_name}.for_record(records)"
          end

        module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def #{name}
          return @__#{name} if instance_variable_defined?("@__#{name}")

          records = record.#{name}
          return nil if records.nil?

          #{wrapping}
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
        ivar_name = case name.to_s
                    when /\?/
                      "is_#{name.to_s[0..-2]}"
                    when /!/
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

      def self.order_mapping(definition = nil)
        if definition.nil?
          @_order_map ||= {} # initialize to empty hash by default
          return @_order_map
        end

        @_order_map = \
          case definition
          when Hash
            definition.transform_values(&:to_s)
          else
            raise 'Resource.orders_mapping only allows a hash'
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

      def self.craft_pagination_query(base_query, pagination:, selectors:)
        handler_klass = model._pagination_query_builder_class
        return base_query unless handler_klass && (pagination.paginator || pagination.order)

        # Gather and save the count if required
        pagination.total_count = handler_klass.count(base_query.dup) if pagination.paginator&.total_count

        base_query = handler_klass.order(base_query, pagination.order, root_resource: selectors.resource)
        handler_klass.paginate(base_query, pagination, root_resource: selectors.resource)
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
      def self.create_override_module(mod:, method:, calls:)
        has_args = method.parameters.any? { |(type, _)| %i[req opt rest].include?(type) }
        has_kwargs = method.parameters.any? { |(type, _)| %i[keyreq keyrest].include?(type) }

        mod.class_eval do
          if has_args && has_kwargs
            # Setup the method to take both args and  kwargs
            define_method(method.name.to_sym) do |*args, **kwargs|
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
            define_method(method.name.to_sym) do |**kwargs|
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
            define_method(method.name.to_sym) do |*args|
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
