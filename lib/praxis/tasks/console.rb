namespace :praxis do
  desc "Run interactive pry/irb console"
  task :console do
    begin
      # Use pry if available; require pry _before_ anything else to maximize
      # debuggability.
      require 'pry'
      Rake::Task['environment'].invoke
      Praxis::Application.instance.pry
    rescue LoadError
      # Fall back on irb; use some special initialization magic to ensure that
      # 'self' in the IRB session refers to Praxis::Application.instance.
      require 'irb'
      Rake::Task['environment'].invoke
      IRB.setup nil
      IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
      require 'irb/ext/multi-irb'
      IRB.irb(nil, Praxis::Application.instance)
  end
end
