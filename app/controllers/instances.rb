class Instances
  include Praxis::Controller

  implements ApiResources::Instances

  before :validate, actions: [:index]  do |controller|
    p [:before, :validate, :params_and_headers, controller.request.action.name]
  end

  before actions: [:show] do
    #puts "before action"
  end

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

  def attach_file(id:, cloud_id:)
    response.headers['Content-Type'] = 'application/json'

    request.payload.parts.each do |name, part|
      p [name, part.headers]
    end

    request.payload.each do |name, part|
    end

    response
  end

  def bulk_create(cloud_id:)
    response.headers['Content-Type'] = 'application/json'

    request.payload.each do |instance_id,instance|
      part_body = JSON.pretty_generate(key: instance_id, value: instance.render(:create))
      headers = {
        'Status' => '201',
        'Content-Type' => Instance.identifier,
        'Location' => self.class.action(:show).primary_route.path.expand(cloud_id: cloud_id, id: instance.id)
      }

      part = Praxis::MultipartPart.new(part_body, headers)

      response.add_part(instance_id, part)
    end

    response
  end


end
