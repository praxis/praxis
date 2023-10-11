# frozen_string_literal: true

namespace :praxis do
  desc 'Run interactive REPL'
  task :console do
    # Use irb if available (which it almost always is).
    require 'irb'
    # Ensure that we save history just like normal IRB
    require 'irb/ext/save-history'

    Rake::Task['praxis:environment'].invoke

    basedir = ::Praxis::Application.instance.root
    nickname = File.basename(::Praxis::Application.instance.root)

    # Keep IRB.setup from complaining about bad ARGV options
    old_argv = ARGV.dup
    ARGV.clear
    IRB.setup(basedir)
    ARGV.concat(old_argv)

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

    # Invoke the REPL, setting the workspace binding to the application object.
    IRB::Irb.new(IRB::WorkSpace.new(::Praxis::Application.instance)).run(
      IRB.conf,
    )
    # Cleanly shut down to ensure we save history
    IRB.irb_at_exit
  end
end
