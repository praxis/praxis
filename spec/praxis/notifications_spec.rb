require 'spec_helper'

describe Praxis::Notifications do
  let(:events) { [] }

  before do
    Praxis::Notifications.subscribe('render') do |_name, _start, _finish, _id, payload|
      events << payload
    end

    Praxis::Notifications.instrument('render', extra: :information) do
    end

    Praxis::Notifications.instrument('render', extra: :single)
  end

  it 'works' do
    expect(events).to have(2).items
    expect(events).to match [{ extra: :information }, { extra: :single }]
  end
end
