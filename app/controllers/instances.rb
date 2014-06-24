class Instances
  include Praxis::Controller

  implements ApiResources::Instances
  
  def index(**params)
    response.headers['Content-Type'] = 'application/json'
    JSON.generate(params)
  end

  def show(cloud_id:, id:, junk:, **other_params)
    payload = request.payload
    response.body = {cloud_id: cloud_id, id: id, junk: junk, other_params: other_params, payload: payload.dump}
    response.headers['Content-Type'] = 'application/json'
    response
  end

end
