# frozen_string_literal: true

namespace :praxis do
  desc 'Run interactive REPL'
  task :console do
    # Use irb if available (which it almost always is).
    require 'irb'

    Rake::Task['praxis:environment'].invoke

    # Keep IRB.setup from complaining about bad ARGV options
    old_argv = ARGV.dup
    ARGV.clear
    IRB.setup nil
    ARGV.concat(old_argv)

    # Ensure that multi-irb has a context to work with (and, indirectly an instance of IRB::Irb).
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context

    # Allow reentrant IRB
    require 'irb/ext/multi-irb'

    # Ensure that we save history just like normal IRB
    require 'irb/ext/save-history'

    # Remove main object from prompt (its stringify is not useful)
    nickname = File.basename(::Praxis::Application.instance.root)
    IRB.conf[:PROMPT][:DEFAULT] = {
      PROMPT_I: "%N(#{nickname}):%03n:%i> ",
      PROMPT_N: "%N(#{nickname}):%03n:%i> ",
      PROMPT_S: "%N(#{nickname}):%03n:%i%l ",
      PROMPT_C: "%N(#{nickname}):%03n:%i* ",
    }

    # Disable inefficient, distracting autocomplete
    IRB.conf[:USE_AUTOCOMPLETE] = false

    # Invoke the REPL, then cleanly shut down
    IRB.irb(nil, Praxis::Application.instance)
    IRB.irb_at_exit
  end
end
