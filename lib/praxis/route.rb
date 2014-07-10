module Praxis

  class Route
    attr_accessor :verb, :path, :version, :name, :options

    def initialize(verb, path, version='n/a', name:nil, **options)
      @verb = verb
      @path = path
      @version = version
      @name = name
      @options = options
    end

    def describe
      result = {
        verb: verb,
        path: path,
        version: version
      }
      result[:name] = name unless name.nil?
      result[:options] = options if options.any?
      result
    end
    
  end

end
