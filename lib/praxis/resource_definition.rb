require 'active_support/concern'
require 'active_support/inflector'

#require 'struct'

SimpleMediaType = Struct.new(:identifier) do
  def ===(other_thing)
    identifier == other_thing
  end
end

module Praxis
  module ResourceDefinition
    extend ActiveSupport::Concern

    included do
      @version = 'n/a'.freeze
      @actions = Hash.new
      @route_prefix = "/" + route_base
    end

    module ClassMethods

      def actions
        @actions
      end

      def route_prefix
        @route_prefix
      end

      def media_type(media_type=nil)
        return @media_type unless media_type

        if media_type.kind_of?(String)
          media_type = SimpleMediaType.new(media_type)
        end
        @media_type = media_type
      end

      def version(version=nil)
        return @version unless version
        @version = version
      end

      def action(name, &block)
        opts = {}
        opts[:media_type] = media_type if media_type
        @actions[name] = Skeletor::RestfulActionConfig.new(name, self, opts, &block)
      end

      def route_base
        class_name = self.name.split("::").last || ""
        class_name.underscore
      end

    end

  end
end
