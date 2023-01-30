# frozen_string_literal: true

namespace :praxis do
  desc "Run interactive pry/irb console"
  task :console do
    # Use irb if available (which it almost always is).
    require "irb"
    have_irb = true

    Rake::Task["praxis:environment"].invoke

    # Keep IRB.setup from complaining about bad ARGV options
    old_argv = ARGV.dup
    ARGV.clear
    IRB.setup nil
    ARGV.concat(old_argv)

    # Allow reentrant IRB
    IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
    require "irb/ext/multi-irb"

    # Use some special initialization magic to ensure that 'self' in the
    # IRB session refers to Praxis::Application.instance.
    IRB.irb(nil, Praxis::Application.instance)
  end
end
