# See http://unicorn.bogomips.org/Unicorn/Configurator.html for complete
# documentation.

APP_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))

if [ 'integration', 'staging', 'production', 'meta' ].include?(ENV['RACK_ENV'])
  PID_FILE = '/var/run/rainbows/rainbows.pid'
  LOG_FILE = '/var/log/rails/rainbows.log'
else
  PID_FILE = File.join(APP_PATH, 'rainbows.pid')
  LOG_FILE = APP_PATH + "/log/rainbows.log"
end

nr_processes = (ENV['RACK_ENV'] == 'development' ? 1 : '@@RAINBOWS_WORKER_PROCESSES@@____'.to_i)
if nr_processes == 0
  raise "Invalid configuration: number of rainbows workers is 0 (was RAINBOWS_WORKER_PROCESSES substituted?)"
end

Rainbows! do
  worker_connections 400
  keepalive_timeout 5 # zero disables keepalives entirely
  client_max_body_size 5*1024*1024 # 5 megabytes
end

worker_processes nr_processes

# All production STs include an application owner field (which we assume to also be the same group)
# Thus use that user and group accordingly to run the application.
if [ 'integration', 'staging', 'production', 'meta' ].include?(ENV['RAILS_ENV'])
  user('@@APPLICATION_OWNER@@','@@APPLICATION_OWNER@@')
end

# Help ensure your application will always spawn in the symlinked
# "current" directory that Capistrano sets up.
working_directory APP_PATH

stderr_path LOG_FILE
stdout_path LOG_FILE

# listen on both a Unix domain socket and a TCP port,
# we use a shorter backlog for quicker failover when busy
# listen 8080, :tcp_nopush => true
listen 8080

# PID file location
pid PID_FILE

# combine REE with "preload_app true" for memory savings
# http://rubyenterpriseedition.com/faq.html#adapt_apps_for_cow
preload_app true

GC.respond_to?(:copy_on_write_friendly=) and GC.copy_on_write_friendly = true

after_fork do |server, worker|
  # re-establish db connections here
end

