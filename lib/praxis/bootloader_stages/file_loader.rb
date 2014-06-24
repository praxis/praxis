module Praxis


  module BootloaderStages

    class FileLoader < Stage

      attr_reader :path

      def initialize(name, application, path: nil)
        super
        @path = path || Array(name)
      end

      def execute
        application.file_layout[*path].each do |file|
          next if application.loaded_files.include?(file)

          require file
          application.loaded_files << file
        end
      end

      def callback_args
        application.file_layout[*path]
      end

    end
  end

end
