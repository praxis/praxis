namespace :praxis do

  desc 'List routes, format=json or table, default table'
  task :routes, [:format] => [:environment] do |t, args|
    require 'terminal-table'

    table = Terminal::Table.new title: "Routes",
    headings:  [
      "Version", "Path", "Verb",
      "Resource", "Action", "Implementation", "Name", "Primary", "Options"
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

        row = {
          resource: resource_definition.name,
          action: name,
          implementation: method_name,
        }

        if action.routes.empty?
          warn "Warning: No routes defined for #{resource_definition.name}##{name}."
          rows << row
        else
          action.routes.each do |route|
            rows << row.merge({
              version: route.version,
              verb: route.verb,
              path: route.path,
              name: route.name,
              primary: (action.primary_route == route ? 'yes' : ''),
              options: route.options
            })
        end
      end
    end
  end

    case args[:format] || "table"
    when "json"
      puts JSON.pretty_generate(rows)
    when "table"
      rows.each do |row|
        formatted_options = row[:options].map{|(k,v)| "#{k}:#{v.to_s}"}.join("\n")
        row_data = row.values_at(:version, :path, :verb, :resource,
                                    :action, :implementation, :name, :primary)
        row_data << formatted_options
        table.add_row(row_data)
      end
      puts table
    else
      raise "unknown output format: #{args[:format]}"
    end

  end
end
