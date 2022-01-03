# frozen_string_literal: true

module Praxis
  class FileGroup
    attr_reader :groups, :base

    def initialize(base, &block)
      if base.nil?
        raise ArgumentError, 'base must not be nil.' \
          'Are you missing a call Praxis::Application.instance.setup?'
      end

      @groups = {}
      @base = Pathname.new(base)

      instance_eval(&block) if block_given?
    end

    def layout(&block)
      instance_eval(&block)
    end

    def map(name, pattern, &block)
      return unless base.exist?

      if block_given?
        @groups[name] = FileGroup.new(base + pattern, &block)
      else
        @groups[name] ||= []
        files = Pathname.glob(base + pattern).select(&:file?)
        files.sort_by! { |file| [file.to_s.split('/').size, file.to_s] }
        files.each { |file| @groups[name] << file }
      end
    end

    def [](*names)
      names.inject(@groups) { |group, name| group[name] || [] }
    end
  end
end
