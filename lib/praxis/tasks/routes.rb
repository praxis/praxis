namespace :praxis do

  desc 'List routes, format=json or table, default table'
  task :routes, [:format] => [:environment] do |t, args|
    require 'ruport'

    table = Table(:version, :path, :verb, :resource, :action, :implementation)

    Praxis::Application.instance.resource_definitions.each do |resource_definition|
      resource_definition.actions.each do |name, action|
        method = begin
          m = resource_definition.controller.instance_method(name)
          "#{m.owner.name}##{m.name}"
        rescue
          'n/a'
        end

        action.routing_config.routes.each do |(verb, path)|
          table << {
            resource: resource_definition.name,
            version: resource_definition.version,
            verb: verb,
            path: path,
            action: name,
            implementation: method.to_s
          }
        end
      end
    end

    case args[:format] || "table"
    when "json"
      puts JSON.pretty_generate(table.collect { |r| r.to_hash })
    when "table"
      puts table.to_s
    else
      raise "unknown output format: #{args[:format]}"
    end

  end
end
