
Praxis::Application.configure do |application|

  # Configure the Mapper plugin (if we want to use all the filtering/field_selection extensions)
  application.bootloader.use Praxis::Plugins::MapperPlugin
  # Cconfigure the Pagination plugin (if we want to use all the pagination/ordering extensions)
  application.bootloader.use Praxis::Plugins::PaginationPlugin, {
    # max_items: 500,  # Unlimited by default,
    # default_page_size: 100,
    # paging_default_mode: {by: :id},
    # disallow_paging_by_default: false,
    # disallow_cursor_by_default: false,
    # sorting: {
    #   enforce_all_fields: true
    # }
  }
  
  # This is a commented out copy of the default Praxis layout
  # This example app follows the standard practices, so there is no reason to override it
  # If we wanted to organize the structure and ordering of files, we can uncomment the layout
  # and define it at our own leisure
  # application.layout do
  #   map :initializers, 'config/initializers/**/*'
  #   map :lib, 'lib/**/*'
  #   map :design, 'design/' do
  #     map :api, 'api.rb'
  #     map :helpers, '**/helpers/**/*'
  #     map :types, '**/types/**/*'
  #     map :media_types, '**/media_types/**/*'
  #     map :endpoints, '**/endpoints/**/*'
  #   end
  #   map :app, 'app/' do
  #     map :models, 'models/**/*'
  #     map :responses, '**/responses/**/*'
  #     map :exceptions, '**/exceptions/**/*'
  #     map :resources, '**/resources/**/*'
  #     map :controllers, '**/controllers/**/*'
  #   end
  # end
end