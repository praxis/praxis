namespace :praxis do

  desc 'List routes, format=json or table, default table'
  task :routes, [:format] => [:environment] do |t, args|
    require 'ruport'

    table = Table(:version, :path, :verb, :resource, 
      :action, :implementation, :name, :primary)

    Praxis::Application.instance.resource_definitions.each do |resource_definition|
      resource_definition.actions.each do |name, action|
        method = begin
          m = resource_definition.controller.instance_method(name)
        rescue
          nil
        end
        
        method_name = method ? "#{method.owner.name}##{method.name}" : 'n/a'

        action.routes.each do |route|
          table << {
            resource: resource_definition.name,
            version: route.version,
            verb: route.verb,
            path: route.path,
            action: name,
            implementation: method_name,
            name: route.name,
            primary: (action.primary_route == route ? 'yes' : '')
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
