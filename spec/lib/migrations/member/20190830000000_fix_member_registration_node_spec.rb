require 'spec_helper'
require Rails.root.join("lib/migrations/member/20190830000000_fix_member_registration_node.rb")

RSpec.describe SS::Migration20190830000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:item) { create :member_node_registration, sender_name: 'admin', sender_email: 'admin@example.jp' }

  it do
    item["subject"] = "subject"
    item["reply_signature"] = "reply_signature"
    item["reset_password_signature"] = "reset_password_signature"
    item.save!

    described_class.new.change

    item.reload
    expect(item.reply_subject).to eq "subject"
    expect(item.sender_signature).to eq "reply_signature\nreset_password_signature"
  end
end
