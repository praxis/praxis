module Praxis

  class Trait
    attr_reader :name
    attr_reader :attribute_groups

    def initialize(&block)
      @name = nil
      @description = nil
      @responses = {}
      @routing = nil
      @other = []

      @attribute_groups = Hash.new do |h,k|
        h[k] = Trait.new
      end

      if block_given?
        self.instance_eval(&block)
      end
    end

    def method_missing(name, *args, &block)
      @other << [name, args, block]
    end

    def description(desc=nil)
      return @description if desc.nil?
      @description = desc
    end

    def response(resp, **args)
      @responses[resp] = args
    end

    def create_group(name, &block)
      @attribute_groups[name] = block
    end

    def headers(*args, &block)
      create_group(:headers,&block)
    end

    def params(*args, &block)
      create_group(:params,&block)
    end

    def payload(*args, &block)
      type, opts = args

      if type && !(type < Attributor::Hash)
        raise 'payload in a trait with non-hash (or model or struct) is not supported'
      end

      create_group(:payload,&block)
    end

    def routing(&block)
      @routing = block
    end

    def describe
      desc = {description: @description}
      desc[:name] = @name if @name
      desc[:responses] = @responses if @responses.any?

      if @routing
        desc[:routing] = ConfigHash.new(&@routing).to_hash
      end

      @attribute_groups.each_with_object(desc) do |(name, block), hash|
        hash[name] = Attributor::Hash.construct(block).describe[:keys]
      end

      desc
    end


    def apply!(target)
      @attribute_groups.each do |name, block|
        target.send(name, &block)
      end
      
      if @routing
        target.routing(&@routing)
      end
      
      @responses.each do |name, args|
        target.response(name, **args)
      end

      if @other.any?
        @other.each do |name, args, block|
          if block
            target.send(name, *args, &block)
          else
            target.send(name,*args)
          end
        end
      end
    end



  end

end
