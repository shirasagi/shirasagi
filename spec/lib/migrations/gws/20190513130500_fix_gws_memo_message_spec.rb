require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20190513130500_fix_gws_memo_message.rb")

RSpec.describe SS::Migration20190513130500, dbscope: :example do
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }
  let(:message1) { create :gws_memo_message, cur_user: user, user_settings: [] }
  let(:message2) { create :gws_memo_message, cur_user: user }

  before do
    message1[:seen] = { user.id.to_s => now }
    message1.save!
    message2.user_settings[0]['seen_at'] = now
    message2.save!
  end

  it do
    described_class.new.change

    message1.reload
    message2.reload

    expect(message1.user_settings[0]['user_id']).to eq user.id
    expect(message1.user_settings[0]['path']).to eq 'INBOX'
    expect(message1.user_settings[0]['seen_at']).to eq now

    expect(message2.user_settings[0]['user_id']).to eq user.id
    expect(message2.user_settings[0]['path']).to eq 'INBOX'
    expect(message2.user_settings[0]['seen_at']).to eq now
  end
end
