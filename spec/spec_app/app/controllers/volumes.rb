class Volumes < BaseClass
  include Praxis::Controller

  implements ApiResources::Volumes
  include Concerns::BasicApi

  before actions: [:show] do |controller|
    #puts "before action for volumes"
  end

  def show(id:, **other_params)
    response.body = { id: id, other_params: other_params }
    response.headers['Content-Type'] = 'application/vnd.acme.volume'
    response
  end

  def index
    response.headers['Content-Type'] = 'application/vnd.acme.volume'
    response
  end

end
