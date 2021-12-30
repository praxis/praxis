# frozen_string_literal: true

module Praxis
  module BootloaderStages
    class WarnUnloadedFiles < Stage
      @enabled = true

      class << self
        attr_writer :enabled
      end

      class << self
        attr_reader :enabled
      end

      def execute
        return unless self.class.enabled

        return if application.file_layout[:app] == []

        base = application.file_layout[:app].base
        return unless base.exist?

        file_enum = base.find.to_a
        files = file_enum.select do |file|
          path = file.relative_path_from(base)
          path.extname == '.rb'
        end

        missing = Set.new(files) - application.loaded_files
        if missing.any?
          msg = "The following application files under #{base} were not loaded:\n"
          missing.each do |file|
            path = file.relative_path_from(base)
            msg << " * #{path}\n"
          end
          warn msg
        end
      end
    end
  end
end
