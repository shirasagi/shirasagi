require 'spec_helper'

describe 'inquiry:pull_answers' do
  it do
    sync = SS::PullSync.new(Inquiry::Answer)
    expect(sync).to be_truthy

    resp = sync.pull_all_and_delete
    expect(resp).to be_truthy
  end
end
