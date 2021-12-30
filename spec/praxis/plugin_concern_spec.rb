require 'spec_helper'

describe Praxis::PluginConcern do
  it 'works' do
    expect(Praxis::Request.instance_methods).to include(:user_abilities)
  end

  context 'ActionDefinition' do
    subject(:action) { ApiResources::Instances.actions[:terminate] }
    its(:required_abilities) { should match_array %i[terminate read] }

    context '#describe' do
      subject(:describe) { action.describe }
      it { should have_key :required_abilities }
      its([:required_abilities]) { should match_array action.required_abilities }
    end
  end
end
