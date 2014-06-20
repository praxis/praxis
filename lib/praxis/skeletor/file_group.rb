module Praxis
  module Skeletor

    class FileGroup

      attr_reader :groups, :base

      def initialize(base, &block)
        @groups = Hash.new
        @base = base

        if block_given?
          self.instance_eval(&block)
        end
      end

      def layout(&block)
        self.instance_eval(&block)
      end

      def map(name, pattern, &block)
        if block_given?
          @groups[name] = FileGroup.new(base + pattern, &block)
        else
          @groups[name] ||= []
          file_enum = base.find.to_a
          files = file_enum.select do |file|
            path = file.relative_path_from(base)
            file.file? && path.fnmatch?(pattern, File::FNM_PATHNAME)
          end
          files.sort_by { |file| [file.to_s.split('/').size, file.to_s] }.each { |file| @groups[name] << file }
        end
      end

      def [](*names)
        names.inject(@groups) { |group, name| group[name] || [] }
      end

    end
  end
end
