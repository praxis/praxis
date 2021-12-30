# frozen_string_literal: true
module Praxis
  module BootloaderStages
    class SubgroupLoader < Stage
      attr_writer :order

      def initialize(name, application)
        super
        # always finalize Taylor after loading app code.
      end

      def order
        @order ||= application.file_layout[name] == [] ? [] : application.file_layout[name].groups.keys
      end

      def setup!
        order.each do |group|
          @stages << FileLoader.new(group, application, path: [name, group])
        end
        setup_deferred_callbacks!
      end
    end
  end
end
