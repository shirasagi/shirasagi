require 'spec_helper'
require Rails.root.join('lib/migrations/ezine/20150408081234_enable_member_state.rb')

RSpec.describe SS::Migration20150408081234, dbscope: :example do
  before do
    member = create :ezine_member
    member.unset :state
  end

  it do
    expect { described_class.new.change }
      .to change { Ezine::Member.enabled.count }.by 1
  end
end
