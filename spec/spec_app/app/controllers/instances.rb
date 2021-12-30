# frozen_string_literal: true

class Instances < BaseClass
  include Praxis::Controller

  implements ApiResources::Instances
  include Concerns::BasicApi

  before :validate, actions: [:index] do |controller|
    # p [:before, :validate, :params_and_headers, controller.request.action.name]
  end

  before actions: [:show] do |controller|
    # puts "before action"
    Praxis::Responses::Unauthorized.new if controller.request.params.fail_filter
  end

  around :validate, actions: [:show] do |_controller, blk|
    # puts "Before validate decorator (for show)"
    blk.call
    # puts "After validate decorator"
  end

  around :action do |_controller, blk|
    # puts "Decorator one (all actions) start"
    blk.call
    # puts "Decorator one end"
  end

  around :action, actions: [:show] do |_controller, blk|
    # puts "Decorator two (show action) start"
    blk.call
    # puts "Decorator two end"
  end

  around :action, actions: [:index] do |_controller, blk|
    # puts "Decorator three (index action) start"
    blk.call
    # puts "Decorator three end"
  end

  def index(response_content_type: 'application/vnd.acme.instance;type=collection', **_params)
    instances = Instance::Collection.example
    response.body = JSON.pretty_generate(instances.collect(&:render))
    response.headers['Content-Type'] = response_content_type # 'application/vnd.acme.instance;type=collection'
    response
  end

  def show(cloud_id:, id:, junk:, create_identity_map:, **other_params)
    request.identity_map if create_identity_map

    payload = request.payload

    response.body = { cloud_id: cloud_id, id: id, junk: junk, other_params: other_params, payload: payload && payload.dump }
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
        value: instance.render(fields: { id: true, name: true })
      }

      headers = {
        'Status' => '201',
        'Content-Type' => "#{Instance.identifier}+json".to_s,
        'Location' => definition.to_href(cloud_id: cloud_id, id: instance.id)
      }

      part = Praxis::MultipartPart.new(part_body, headers, name: instance_id)
      response.body.push(part)
    end

    response
  end

  def attach_file(*)
    response.headers['Content-Type'] = 'application/json'

    destination_path = request.payload.part('destination_path').payload
    file = request.payload.part('file')
    file.payload.rewind # Ensure contents is at the beggining.
    extra_part_names = request.payload.map(&:name) - %w[destination_path file]
    extra_parts = extra_part_names.each_with_object({}) do |pname, hash|
      hash[pname] = request.payload.part(pname).body
    end
    result = {
      destination_path: destination_path,
      name: file.name,
      filename: file.filename,
      type: file.content_type.to_s,
      contents: file.payload.read,
      options: extra_parts
    }

    response.body = JSON.pretty_generate(result)

    response
  end

  def terminate(*)
    response.headers['Content-Type'] = 'application/json'
    response
  end

  def stop(*)
    response.headers['Content-Type'] = 'application/json'
    response
  end

  def update(*)
    response.body = JSON.pretty_generate(request.payload.dump)
    response.headers['Content-Type'] = 'application/vnd.acme.instance'
    response
  end

  def exceptional(*)
    response.headers['Content-Type'] = 'application/json'
    response
  end
end
