class Instances < BaseClass
  include Praxis::Controller

  implements ApiResources::Instances
  include Concerns::BasicApi

  before :validate, actions: [:index]  do |controller|
    #p [:before, :validate, :params_and_headers, controller.request.action.name]
  end

  before actions: [:show] do |controller|
    #puts "before action"
    if controller.request.params.fail_filter
      Praxis::Responses::Unauthorized.new
    end
  end

  around :validate, actions: [:show] do |controller, blk|
    #puts "Before validate decorator (for show)"
    blk.call
    #puts "After validate decorator"
  end

  around :action do |controller, blk|
    #puts "Decorator one (all actions) start"
    blk.call
    #puts "Decorator one end"
  end

  around :action, actions: [:show] do |controller, blk|
    #puts "Decorator two (show action) start"
    blk.call
    #puts "Decorator two end"
  end

  around :action, actions: [:index] do |controller, blk|
    #puts "Decorator three (index action) start"
    blk.call
    #puts "Decorator three end"
  end

  def index(cloud_id:, response_content_type: 'application/vnd.acme.instance;type=collection', **params)
    instances = Instance::Collection.example
    response.body = JSON.pretty_generate(instances.collect { |i| i.render })
    response.headers['Content-Type'] = response_content_type #'application/vnd.acme.instance;type=collection'
    response
  end

  def show(cloud_id:, id:, junk:, create_identity_map:, **other_params)
    if create_identity_map
      request.identity_map
    end

    payload = request.payload

    response.body = {cloud_id: cloud_id, id: id, junk: junk, other_params: other_params, payload: payload && payload.dump}
    response.headers['Content-Type'] = 'application/json'
    response
  end

  def bulk_create(cloud_id:)
    self.response = Praxis::Responses::MultipartOk.new
    response.body = request.action.responses[:multipart_ok].media_type.new

    request.payload.each do |part|
      instance_id = part.name
      instance = part.payload

      part_body = {
        key: instance_id,
        value: instance.render(view: :create)
      }

      headers = {
        'Status' => '201',
        'Content-Type' => (Instance.identifier + '+json').to_s,
        'Location' => definition.to_href(cloud_id: cloud_id, id: instance.id)
      }

      part = Praxis::MultipartPart.new(part_body, headers, name: instance_id)

      response.body.push(part)
    end

    response
  end


  def attach_file(id:, cloud_id:)
    response.headers['Content-Type'] = 'application/json'

    destination_path = request.payload['destination_path']
    file = request.payload['file']

    result = {
      destination_path: destination_path,
      file: file.dump,
      options: request.payload['options'].dump
    }

    response.body = JSON.pretty_generate(result)

    response
  end

  def terminate(id:, cloud_id:)
    response.headers['Content-Type'] = 'application/json'
    response
  end

  def stop(id:, cloud_id:)
    response.headers['Content-Type'] = 'application/json'
    response
  end

  def update(id:, cloud_id:)
    response.body = JSON.pretty_generate(request.payload.dump)
    response.headers['Content-Type'] = 'application/vnd.acme.instance'
    response
  end

  def exceptional(cloud_id:, splat:)
    response.headers['Content-Type'] = 'application/json'
    response
  end
end
