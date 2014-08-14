module Praxis
  module ContentTypeParser
    REGEXP = /^
      \s*
      (?<type>[^+;\s]+)
      (\+(?<sub_type>[^;\s]+))?
      (\s*;\s*)?
      (?<params>.*?)?
      (\s*;\s*)?
    $/x

    # Parses Content type
    #
    # @param  [String]         Content type to parse
    # @return [Hash]           A hash with keys: :type, :sub_type(optional) and :params(optional)
    # @raise  [ArgumentError]  It fails when blank or weird content type is provided
    #
    # @example
    #   parse(nil)      #=> Exception: Content type does not have any type defined (ArgumentError)
    #   parse('+json')  #=> Exception: Content type does not have any type defined (ArgumentError)
    #   parse(';p1=11') #=> Exception: Content type does not have any type defined (ArgumentError)
    #
    # @example
    #   parse('text/xml') #=>
    #     {:type     => "text/xml",
    #      :sub_type => nil,
    #      :params   => {}}
    #
    # @example
    #   parse('application/vnd.something+json') #=>
    #     {:type     => "application/vnd.something",
    #      :sub_type => "json",
    #      :params   => {}}
    #
    # @example
    #   parse('application/vnd.something+json;p1=1.0;param_with_noval;p2=a13') #=>
    #     {:type     => "application/vnd.something",
    #      :sub_type => "json",
    #      :params   => {"p1"=>"1.0", "param_with_noval"=>nil, "p2"=>"a13"}}
    #
    def self.parse(content_type)
      parsed = REGEXP.match(content_type.to_s)
      raise(ArgumentError, 'Content type does not have any type defined') unless parsed

      result = {
        type: parsed[:type]
      }
      result[:sub_type] = parsed[:sub_type] if parsed[:sub_type]
      if parsed[:params]
        params = {}
        parsed[:params].split(';').each do |param|
          key, value = param.split('=')
          key        = key.to_s.strip
          next if key.empty?
          params[key.strip] = value && value.strip
        end
        result[:params] = params unless params.empty?
      end
      result
    end
  end
end
