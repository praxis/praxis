namespace :praxis do
  desc 'List routes, format=json or table, default table'
  task :routes, [:format] => [:environment] do |_t, args|
    require 'terminal-table'

    table = Terminal::Table.new title: 'Routes',
                                headings: %w[
                                  Version Path Verb
                                  Endpoint Action Implementation Options
                                ]

    rows = []
    Praxis::Application.instance.endpoint_definitions.each do |endpoint_definition|
      endpoint_definition.actions.each do |name, action|
        method = begin
          m = endpoint_definition.controller.instance_method(name)
        rescue StandardError
          nil
        end

        method_name = method ? "#{method.owner.name}##{method.name}" : 'n/a'

        row = {
          resource: endpoint_definition.name,
          action: name,
          implementation: method_name
        }

        if action.route
          route = action.route
          rows << row.merge({
                              version: route.version,
                              verb: route.verb,
                              path: route.path,
                              options: route.options
                            })
        else
          warn "Warning: No routes defined for #{endpoint_definition.name}##{name}."
          rows << row
        end
      end
    end
    case args[:format] || 'table'
    when 'json'
      puts JSON.pretty_generate(rows)
    when 'table'
      rows.each do |row|
        formatted_options = row[:options].map { |(k, v)| "#{k}:#{v}" }.join("\n")
        row_data = row.values_at(:version, :path, :verb, :resource,
                                 :action, :implementation)
        row_data << formatted_options
        table.add_row(row_data)
      end
      puts table
    else
      raise "unknown output format: #{args[:format]}"
    end
  end
end
