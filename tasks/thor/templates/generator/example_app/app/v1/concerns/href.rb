# frozen_string_literal: true

module V1
  module Resources
    module Concerns
      module Href
        extend ActiveSupport::Concern

        # Base module where the href concern will grab constants from
        included do
          def self.base_module
            ::V1
          end
        end

        module ClassMethods
          mutex = Mutex.new
          
          def endpoint_path_template
            # memoize a templated path for an endpoint, like
            # /users/%{id}
            return @endpoint_path_template if @endpoint_path_template # rubocop:disable ThreadSafety/InstanceVariableInClassMethod

            mutex.synchronize do
              return @endpoint_path_template if @endpoint_path_template # rubocop:disable ThreadSafety/InstanceVariableInClassMethod

              path = self.base_module.const_get(:Endpoints).const_get(model.name.split(':').last.pluralize).canonical_path.route.path
              @endpoint_path_template = path.names.inject(path.to_s) { |p, name| p.sub(':' + name, "%{#{name}}") }  
            end
          end
        end

        def href
          format(self.class.endpoint_path_template, id: id)
        end
      end
    end
  end
end
