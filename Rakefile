$:.unshift File.expand_path('lib',__dir__)

require 'praxis'
require 'praxis/tasks'


require 'rake/notes/rake_task'

require 'right_support'

if require_succeeds?('right_develop')
  RightDevelop::CI::RakeTask.new
  #task 'ci:prep' => ['my_special_task_here'] # optional, if your project needs special setup before running CI
end