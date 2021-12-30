# frozen_string_literal: true

module PraxisGen
  class Model < Thor
    require 'active_support/inflector'
    include Thor::Actions

    def self.source_root
      File.dirname(__FILE__) + '/templates/generator/scaffold'
    end

    desc 'gmodel', 'Generates a skeleton model file under app/models for ActiveRecord or Sequel.'
    argument :model_name, required: true
    option :orm, required: false, default: 'activerecord', enum: %w[activerecord sequel]
    def g
      # self.class.check_name(model_name)
      template_file = \
        if options[:orm] == 'activerecord'
          'models/active_record.rb'
        else
          'models/sequel.rb'
        end
      puts "Generating Model for #{model_name}"
      template template_file, "app/models/#{model_name}.rb"
      nil
    end
    # Helper functions (which are available in the ERB contexts)
    no_commands do
      def model_class
        model_name.camelize
      end
    end

    # TODO: do we want the argument to be camelcase? or snake case?
    def self.check_name(name)
      sanitized = name.downcase.gsub(/[^a-z0-9_]/, '')
      raise 'Please use only downcase letters, numbers and underscores for the model' unless sanitized == name
    end
  end
end
