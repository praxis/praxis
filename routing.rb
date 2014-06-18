require 'pp'
require 'json'

require 'bundler/setup'

require 'pry'

require 'rack/mount'

require_relative 'lib/praxis'


CONTEXT_FOR = {
  params: [Attributor::AttributeResolver::ROOT_PREFIX, "params".freeze],
  headers: [Attributor::AttributeResolver::ROOT_PREFIX, "headers".freeze],
  payload: [Attributor::AttributeResolver::ROOT_PREFIX, "payload".freeze]
}.freeze


class DefaultResponse < Praxis::Response
  self.response_name = :default

  def handle
    @status = 200
    puts "handling: #{@name}"
  end

end


class NotFoundResponse < Praxis::Response
  self.response_name = :not_found

  def handle
    @status = 404
    puts "handling: #{@name}"
  end

end


class ApiRoot
  @responses = Hash.new

  def self.response(name, &block)
    return @responses[name] unless block_given?
    @responses[name] =  Praxis::Skeletor::ResponseDefinition.new(name,&block)
  end

  response :default do
    mime_type :controller_defined
    status 200
  end

  response :not_found do
    status 404
  end
end



class InstancesConfig  < Praxis::Skeletor::RestfulSinatraApplicationConfig
  mime_type 'application/json'

  action :index do
    routing do
      get '/instances'
    end
    params do
    end
  end

  action :show do
    routing do
      get '/instances/:id'
    end
    headers do
      header :version
    end
    params do
      attribute :id, Integer, required: true, min: 1
      attribute :junk, String, default: ''
      attribute :some_date, DateTime, default: DateTime.now
    end
    payload do
      attribute :something, String, required: true
      attribute :optional, String, default: "not given"
    end
  end

  action :initialize do
  end

end


class Instances
  include Praxis::Controller


  def index(**params)
    response.headers['Content-Type'] = 'application/json'
    JSON.generate(params)
  end

  def show(id:, junk:, **params)
    response.body = {id: id, junk: junk, params: params}
    response.headers['Content-Type'] = 'application/json'

    response
  end

end




def coalesce_inputs!(request)
  request.raw_params
  request.raw_payload
end


def load_headers(action, request)
  return unless action.headers
  defined_headers = action.headers.attributes.keys.each_with_object(Hash.new) do |name, hash|
    env_name = if name == :CONTENT_TYPE || name == :CONTENT_LENGTH
      name.to_s
    else
      "HTTP_#{name}"
    end
    hash[name] = request.env[env_name] if request.env.has_key? env_name
  end
  request.headers = action.headers.load(defined_headers,CONTEXT_FOR[:headers])
end


def load_params(action_config, request)
  request.params = action_config.params.load(request.raw_params)
end


def load_payload(action_config, request)
  request.payload = action_config.payload.load(request.raw_payload)
end


def validate_headers(request)
  return unless request.headers
  errors = request.headers.validate(CONTEXT_FOR[:headers])
  raise "nope: #{errors.inspect}" if errors.any?
end


def validate_params(request)
  errors = request.params.validate(CONTEXT_FOR[:params])
  raise "nope: #{errors.inspect}" if errors.any?
end


def validate_payload(request)
  errors = request.params.validate(CONTEXT_FOR[:payload])
  raise "nope: #{errors.inspect}" if errors.any?
end



def setup_request(action, request)
  coalesce_inputs!(request)

  load_headers(action, request)
  load_params(action, request)

  attribute_resolver = Attributor::AttributeResolver.new
  Attributor::AttributeResolver.current = attribute_resolver

  attribute_resolver.register("headers",request.headers)
  attribute_resolver.register("params",request.params)

  validate_headers(request)
  validate_params(request)

  # TODO: handle multipart requests
  if action.payload
    load_payload(action, request)
    attribute_resolver.register("payload",request.payload)
    validate_payload(request)
  end

  params = request.params_hash
  if action.payload
    params[:payload] = request.payload
  end

  params
end


def dispatch(controller, action, request)
  params = setup_request(action, request)
  
  controller_instance = controller.new(request)
  response = controller_instance.send(action.name, **params)

  if response.kind_of? String
    controller_instance.response.body = response
  else
    controller_instance.response = response
  end

  response = controller_instance.response
  
  response.handle
  response.validate(action)

  response.to_rack
end


def target_factory(controller, action_name)
  action = controller.action(action_name)

  unless (method = controller.instance_method(action_name))
    raise "No action with name #{action_name} defined on #{controller.name}"
  end

  Proc.new do |env|
    dispatch(controller, action, Praxis::Request.new(env))
  end
end


route_set = Rack::Mount::RouteSet.new do |set|

  set.add_route target_factory(Instances, :index),
    path_info:  /^\/instances$/.freeze,
    request_method: 'GET'

  set.add_route target_factory(Instances, :show),
    path_info:  /^\/instances\/(?<id>.*)$/.freeze,
    request_method: 'GET'

end


env = Rack::MockRequest.env_for('/instances/1?junk=foo')
env['rack.input'] = StringIO.new('something=given')
#env = Rack::MockRequest.env_for('/instances')
env['HTTP_VERSION'] = 'HTTP/1.1'

status, headers, body = route_set.call(env)
puts "status: #{status}"
puts "headers: #{headers}"
puts "----------"
pp body



