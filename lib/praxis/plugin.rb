# frozen_string_literal: true

module Praxis
  # one instance is created per use.
  class Plugin
    attr_accessor :application, :block, :config, :config_attribute

    def options
      @options ||= {}
    end

    def config_key; end

    def prepare_config!(node); end

    def load_config!
      return unless options.has_key?(:config_file)
      return {} unless (application.root + options[:config_file]).exist?

      YAML.load_file(application.root + options[:config_file])
    end

    def setup!; end

    def register_doc_browser_plugin(path)
      application.doc_browser_plugin_paths << File.expand_path(path)
    end

    def after(stage, &block)
      application.bootloader.after(stage, &block)
    end

    def before(stage, &block)
      application.bootloader.before(stage, &block)
    end
  end
end
