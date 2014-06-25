

# # Defines a simple DSL for describing a RESTful API.
# module Praxis
#   module Skeletor
#     class RestfulSinatraApplicationConfig

#        # def self.inherited(klass)
#        #   klass.configure_default_routing
#        # end

#       # def self.route_base
#       #   # #93 - Revisit whether we can just use ActiveSupport instead
#       #   class_name = self.name.split("::").last || ""

#       #   # class_name.gsub!(%r{Config$},'')
#       #   # perform ActiveSupport-like "underscore" operation on the string
#       #   class_name.gsub!(%r/(?:([A-Za-z\d])|^)((?=a)b)(?=\b|[^a-z])/) { "#{$1}#{$1 && '_'}#{$2.downcase}" }
#       #   class_name.gsub!(%r/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
#       #   class_name.gsub!(%r/([a-z\d])([A-Z])/,'\1_\2')
#       #   class_name.tr!("-", "_")
#       #   class_name.downcase!

#       #   class_name
#       # end

#       # def self.configure_default_routing
#       #   @parent = nil
#       #   @route_prefix = "/" + self.route_base
#       # end

#       # def self.route_prefix
#       #   @route_prefix
#       # end

#       # def self.api_version
#       #   settings[:api_version] || Skeletor::Request::UNVERSIONED
#       # end

#       # def self.parent
#       #   @parent
#       # end

#       # def self.parent_id_param_name
#       #   return nil if @parent.nil?

#       #   # FIXME: should do Skeletor::Doc::Support.camel_case parent
#       #   parent_singular = Skeletor::Doc::Support.singularize(parent.route_base)
#       #   parent_singular.gsub!("/", "")
#       #   "#{parent_singular}_id"
#       # end


#       # def self.routing(route_prefix: nil, parent: nil)
#       #   if parent && !route_prefix
#       #     @parent = parent
#       #     if parent < RestfulSinatraApplication #support legacy mode, where controller classes are passed, instead of Configs
#       #       warn "Deprecated use of parent in routing: please pass a *Config class as the parent, not a controller (got: #{parent.name})! "
#       #       @parent = parent.config_class 
#       #     end
#       #     @route_prefix = "#{self.parent.route_prefix}/:#{self.parent_id_param_name}/#{self.route_base}"
#       #     return
#       #   end

#       #   if route_prefix
#       #     if parent
#       #       @parent = parent
#       #       if parent < RestfulSinatraApplication #support legacy mode, where controller classes are passed, instead of Configs
#       #         warn "Deprecated use of parent in routing: please pass a *Config class as the parent, not a controller (got: #{parent.name})! "
#       #         @parent = parent.config_class 
#       #       end
#       #       @route_prefix = "#{self.parent.route_prefix}/:#{self.parent_id_param_name}/#{route_prefix}"
#       #     else
#       #       @route_prefix = route_prefix
#       #     end

#       #     segments = @route_prefix.split('/').collect do |segment|
#       #       segment.gsub(/(:\w+)/) { |m| '(.*?)' }
#       #     end

#       #     return
#       #   end
#       #   raise ArgumentError, "No routing parameters. You don't want this controller routed at all?"
#       # end


#       class << self
        
#         # def local_settings
#         #   @settings ||= {:strict_responses => false }
#         # end
        
#         # def set( name, value )
#         #   local_settings[name] = value
#         # end
        
#         # def description( text = nil )
#         #   @description = text if text
#         #   @description
#         # end
        
#         # def settings
#         #   inherited = if superclass < RestfulSinatraApplicationConfig
#         #       superclass.settings
#         #   end
            
#         #   if inherited 
#         #     inherited.merge(local_settings)
#         #   else
#         #     local_settings 
#         #   end
#         # end

#         # def actions
#         #   @actions ||= Hash.new
#         # end

#         # def responses
#         #   @responses ||= Hash.new
#         # end
        
#         # 'action' stanza of DSL
#         # def action(name, &block)
#         #   opts = {}
#         #   opts[:media_type] = media_type if media_type
#         #   actions[name] = Skeletor::RestfulActionConfig.new(name, self, opts, &block)
#         # end

#         # def mime_type(mime_string=nil)
#         #   return @mime_type unless mime_string
#         #   raise "Invalid mime type specification" unless mime_string.is_a? String
#         #   @mime_type = mime_string
#         # end

#         # 'media_type' stanza of DSL
#         # def media_type( media_type_class = nil )
#         #   return  @media_type unless media_type_class

#         #   if @media_type || @mime_type
#         #     raise Exception, "A media (or mime_type) type has already been defined in this config (#{self.inspect}"
#         #   end
#         #   unless actions.empty?
#         #     raise Exception, "One or more actions have already been defined, please define the media_type first"
#         #   end
#         #   raise "Invalid media type parameter (must be a class)" unless media_type_class.is_a? Class
#         #   raise "MediaType class for a config must derive from Skeletor::MediaType" unless media_type_class < Skeletor::MediaType
#         #   @media_type = media_type_class
#         #   mime_type( @media_type.mime_type ) if @media_type.mime_type
#         # end


#         # def describe
#         #   {}.tap do |hash|
#         #     hash[:description] = description
#         #     hash[:media_type] = media_type.name if media_type
#         #     hash[:mime_type] = mime_type if mime_type
#         #     hash[:actions] = actions.values.map(&:describe)
#         #   end
#         # end

#         # # 'response' stanza of DSL
#         # def response( name , &block )
#         #    raise "Response definition for #{name} requires a block" unless block_given?
#         #    responses[name] =  ResponseDefinition.new(name,&block)
#         # end
      
        
#       end

#     end
#   end
# end