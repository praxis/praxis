# Configuring a Praxis application
Praxis allows you to define the configuration your application will use
upon startup. Let's look at an example application to see how this works:
```ruby
class MyApplication < Praxis::Application
end

app = MyApplication.instance
```
## Define
Given an instance of your application, you can define the structure of its
configuration by passing a block to #config. Within the block, you can define
attributes in an Attributor::Struct. You can call define with a block multiple
times if you need to define configuration in multiple places.
```ruby
app.config do
  attribute :db, hash do
    attribute :hostname, Attributor::String
    attribute :port, Attributor::Integer
    attribute :username, Attributor::String
    attribute :password, Attributor::String
  end

  attribute :log_level, Attributor::String, required: true
end
```

## Set
After you've defined your application's configuration, you can set the actual
values to use when the application starts. You can call #config= with any
object that will satisfy your configuration definition.  Praxis doesn't mandate
any particular configuration store. In this example, we'll use a YAML file:
```ruby
values = YAML.load(File.read('./config/application.yml'))
# {
#   'db' => {
#     'hostname' => 'localhost',
#     'username' => 'root',
#     'password' => 'mydbpass'
#   },
#   'log_level' => 'info'
# }
app.config = YAML.load(values)
```

## Access
As long as you have a reference to your application instance, you can access
configuration values using the '#config' method.
```ruby
app.config.db.hostname
=> 'localhost'
```
