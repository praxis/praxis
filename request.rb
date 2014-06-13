
class Request
  attr_reader :env

  def initialize(env)
    @env = env
  end

  def params
    @env['praxis.params'.freeze]
  end

  def payload
    @env['praxis.payload'.freeze]
  end

  def headers
    @env['praxis.headers'.freeze]
  end

  def params=(params)
    @env['praxis.params'.freeze] = params
  end

  def payload=(payload)
    @env['praxis.payload'.freeze] = payload
  end

  def headers=(headers)
    @env['praxis.headers'.freeze] = headers
  end

  def params_hash
    params.dump
  end

  def raw_params
    @env['praxis.raw_params'.freeze] ||= begin
      query = Rack::Utils.parse_nested_query(env['QUERY_STRING'.freeze])
      routing = env['rack.routing_args'.freeze]
      query.merge(routing)
    end
  end

  def raw_payload
    @env['praxis.raw_payload'.freeze] ||= begin
      if (input = env['rack.input'.freeze].read)
        env['rack.input'.freeze].rewind
        # FIXME: handle non-url-form-encoded inputs
        Rack::Utils.parse_nested_query(input)
      end
    end
  end

end

