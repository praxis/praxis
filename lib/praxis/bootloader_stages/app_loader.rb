module Praxis

  module BootloaderStages

    class AppLoader < Stage

      attr_writer :order

      def initialize(name, application)
        super
        # always finalize Taylor after loading app code.
        #after do
        #  ::Taylor.finalize!
        #end
      end

      def order
        @order ||= application.file_layout[:app].groups.keys
      end

      def setup!
        order.each do |group|
          @stages << FileLoader.new(group, application, path: [:app, group])
        end
      end
    end

  end
end
