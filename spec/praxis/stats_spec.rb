require 'spec_helper'

describe Praxis::Stats do

  its(:collector) { should be Harness.collector }
  its(:queue)   { should be Harness.queue }
  its(:config) { should be Harness.config }

end