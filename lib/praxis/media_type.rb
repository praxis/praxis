module Praxis
  class MediaType < Taylor::Blueprint

    def self.description(text=nil)
      @description = text if text
      @description
    end
    
    def self.identifier(identifier=nil)
      return @identifier unless identifier
      # TODO: parse the string and extract things like collection , and format type?...
      @identifier = identifier
    end

    def self.describe(shallow = false)
      super.merge!(identifier: @identifier, description: @description)
    end

    def self.===(other_thing)
      case other_thing
      when String
        identifier == other_thing
      when MediaType
        identifier == other_thing.identifier
      else
        raise 'can not compare'
      end
    end

  end
end
