require 'spec_helper'
require Rails.root.join("lib/migrations/inquiry/20250609000000_update_notice_emails.rb")

RSpec.describe SS::Migration20250609000000, dbscope: :example do
  let(:email1) { "#{unique_id}@example.jp" }
  let(:email2) { "#{unique_id}@example.jp;#{unique_id}@example.jp" }
  let(:email3) { "#{unique_id}@example.jp" }

  it do
    model = Class.new do
      include SS::Document
      store_in collection: 'cms_nodes'
      seqid :id
      field :notice_email, type: String
    end

    node1 = create(:inquiry_node_form, notice_emails: nil)
    node2 = create(:inquiry_node_form, notice_emails: nil)
    node3 = create(:inquiry_node_form, notice_emails: [email3])

    model.find(node1.id).set(notice_email: email1)
    model.find(node2.id).set(notice_email: email2)

    node1.reload
    node2.reload
    expect(node1[:notice_email]).to eq email1
    expect(node2[:notice_email]).to eq email2

    described_class.new.change

    node1.reload
    node2.reload
    node3.reload

    expect(node1.notice_emails).to eq [email1]
    expect(node2.notice_emails).to eq [email2]
    expect(node3.notice_emails).to eq [email3]
  end
end
