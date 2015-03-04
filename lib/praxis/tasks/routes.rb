namespace :praxis do

  desc 'List routes, format=json or table, default table'
  task :routes, [:format] => [:environment] do |t, args|
    require 'terminal-table'

    table = Terminal::Table.new title: "Routes",
    headings:  [
      "Version", "Path", "Verb",
      "Resource", "Action", "Implementation", "Name", "Primary"
    ]

    rows = []
    Praxis::Application.instance.resource_definitions.each do |resource_definition|
      resource_definition.actions.each do |name, action|
        method = begin
          m = resource_definition.controller.instance_method(name)
        rescue
          nil
        end

        method_name = method ? "#{method.owner.name}##{method.name}" : 'n/a'

        if action.routes.empty?
          raise "No routes defined for #{resource_definition.name}##{name}."
        end

        action.routes.each do |route|
          rows << {
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
      puts JSON.pretty_generate(rows)
    when "table"
      rows.each do |row|
        table.add_row(row.values_at(:version, :path, :verb, :resource,
                                    :action, :implementation, :name, :primary))
      end
      puts table
    else
      raise "unknown output format: #{args[:format]}"
    end

  end
end
