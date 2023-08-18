require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200117000000_set_send_notice_mail_addresses.rb")

RSpec.describe SS::Migration20200117000000, dbscope: :example do
  let!(:user0) { create :gws_user }
  let!(:user1) { create :gws_user }
  let!(:user2) { create :gws_user }
  let(:valid_email1) { "#{unique_id}@example.jp" }
  let(:invalid_email1) { unique_id }

  before do
    # user1 has valid email address
    user1[:send_notice_mail_address] = valid_email1
    user1.save!

    # user2 has invalid email address
    user2[:send_notice_mail_address] = invalid_email1
    user2.save!

    described_class.new.change
  end

  it do
    user0.reload
    expect(user0[:send_notice_mail_address]).to be_blank
    expect(user0.send_notice_mail_addresses).to be_blank

    user1.reload
    expect(user1[:send_notice_mail_address]).to be_blank
    expect(user1.send_notice_mail_addresses).to eq [ valid_email1 ]

    user2.reload
    expect(user2[:send_notice_mail_address]).to be_blank
    expect(user2.send_notice_mail_addresses).to eq [ invalid_email1 ]
  end
end
