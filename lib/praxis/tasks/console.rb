namespace :praxis do
  desc "Run interactive pry/irb console"
  task :console do
    have_pry = false

    begin
      # Use pry if available; require pry _before_ environment to maximize
      # debuggability.
      require 'pry'
      have_pry = true
    rescue LoadError
      # Fall back on irb
      require 'irb'
    end

    Rake::Task['praxis:environment'].invoke

    if have_pry
      Praxis::Application.instance.pry
    else
      # Keep IRB.setup from complaining about bad ARGV options
      old_argv = ARGV.dup
      ARGV.clear
      IRB.setup nil
      ARGV.concat(old_argv)

      # Allow reentrant IRB
      IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
      require 'irb/ext/multi-irb'

      # Use some special initialization magic to ensure that 'self' in the
      # IRB session refers to Praxis::Application.instance.
      IRB.irb(nil, Praxis::Application.instance)
    end
  end
end
