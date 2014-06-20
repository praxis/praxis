class Instances
  include Praxis::Controller

  implements ApiResources::Instances
  
  def index(**params)
    response.headers['Content-Type'] = 'application/json'
    JSON.generate(params)
  end

  def show(id:, junk:, **other_params)
    payload = request.payload
    response.body = {id: id, junk: junk, other_params: other_params, payload: payload.dump}
    response.headers['Content-Type'] = 'application/json'
    response
  end

end
