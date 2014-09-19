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

  def index(response_content_type:, **params)
    response.headers['Content-Type'] = response_content_type #'application/vnd.acme.instance;type=collection'
    JSON.generate(params)
  end

  def show(cloud_id:, id:, junk:, **other_params)
    payload = request.payload
    response.body = {cloud_id: cloud_id, id: id, junk: junk, other_params: other_params, payload: payload.dump}
    response.headers['Content-Type'] = 'application/vnd.acme.instance'
    response
  end

  def bulk_create(cloud_id:)
    self.response = BulkResponse.new

    request.payload.each do |instance_id,instance|
      part_body = JSON.pretty_generate(key: instance_id, value: instance.render(:create))
      headers = {
        'Status' => '201',
        'Content-Type' => Instance.identifier,
        'Location' => self.class.definition.actions[:show].primary_route.path.expand(cloud_id: cloud_id, id: instance.id)
      }

      part = Praxis::MultipartPart.new(part_body, headers)

      response.add_part(instance_id, part)
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


end
