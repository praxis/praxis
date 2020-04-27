module Praxis

  class Route
    attr_accessor :verb, :path, :version, :name, :prefixed_path, :options

    def initialize(verb, path, version='n/a', name:nil, prefixed_path:nil, **options)
      @verb = verb
      @path = path
      @version = version
      @name = name
      @options = options
      @prefixed_path = prefixed_path
    end

    def example(example_hash:{}, params:)
      path_param_keys = self.path.named_captures.keys.collect(&:to_sym)

      param_attributes = params ? params.attributes : {}
      query_param_keys = param_attributes.keys - path_param_keys
      required_query_param_keys = query_param_keys.each_with_object([]) do |p, array|
        array << p if params.attributes[p].options[:required]
      end

      path_params = example_hash.select{|k,v| path_param_keys.include? k }
      # Let's generate the example only using required params, to avoid mixing incompatible parameters
      query_params = example_hash.select{|k,v| required_query_param_keys.include? k }
      example = { verb: self.verb, url: self.path.expand(path_params.transform_values(&:to_s)), query_params: query_params }

    end

    def describe
      result = {
        verb: verb,
        path: path.to_s,
        version: version
      }
      result[:name] = name unless name.nil?
      result[:options] = options if options.any?
      result
    end

  end

end
