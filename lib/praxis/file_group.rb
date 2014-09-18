module Praxis

  class FileGroup

    attr_reader :groups, :base

    def initialize(base, &block)
      if base.nil?
        raise ArgumentError, "base must not be nil." \
          "Are you missing a call Praxis::Application.instance.setup?" 
      end


      @groups = Hash.new
      @base = Pathname.new(base)

      if block_given?
        self.instance_eval(&block)
      end
    end

    def layout(&block)
      self.instance_eval(&block)
    end

    def map(name, pattern, &block)
      return unless base.exist?

      if block_given?
        @groups[name] = FileGroup.new(base + pattern, &block)
      else
        @groups[name] ||= []
        files = Pathname.glob(base+pattern).select { |file| file.file? }
        files.sort_by! { |file| [file.to_s.split('/').size, file.to_s] }
        files.each { |file| @groups[name] << file }
      end
    end

    def [](*names)
      names.inject(@groups) { |group, name| group[name] || [] }
    end

  end
end
