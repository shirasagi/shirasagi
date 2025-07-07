require 'spec_helper'

describe Inquiry::Node::Base, type: :model, dbscope: :example do
  let(:item) { create :inquiry_node_base }
  it_behaves_like "cms_node#spec"
end

describe Inquiry::Node::Form, type: :model, dbscope: :example do
  context "node" do
    let(:item) { create :inquiry_node_form }
    it_behaves_like "cms_node#spec"
  end

  context "released and first_released" do
    let(:item) { create :inquiry_node_form }

    it do
      expect(item.released).to be_present
      expect(item.first_released).to be_present
    end
  end

  context "notice_emails and from_email" do
    let(:valid_email) { "sample@example.jp" }
    let(:invalid_email) { "sample＠example.jp" }

    let(:valid_emails1) { ["sample@example.jp"] }
    let(:valid_emails2) { ["sample1@example.jp", "sample2@example.jp"] }
    let(:invalid_emails1) { ["sample＠example.jp"] }
    let(:invalid_emails2) { ["sample1@example.jp", "name <sample2@example.jp>"] }

    it do
      item = build(:inquiry_node_form, notice_state: "disabled", notice_emails: nil, from_email: nil)
      expect(item.valid?).to be_truthy
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: nil, from_email: nil)
      expect(item.valid?).to be_falsey
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: valid_emails1, from_email: nil)
      expect(item.valid?).to be_falsey
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: nil, from_email: valid_email)
      expect(item.valid?).to be_falsey
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: valid_emails1, from_email: valid_email)
      expect(item.valid?).to be_truthy
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: valid_emails2, from_email: valid_email)
      expect(item.valid?).to be_truthy
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: invalid_emails1, from_email: valid_email)
      expect(item.valid?).to be_falsey
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: invalid_emails2, from_email: valid_email)
      expect(item.valid?).to be_falsey
    end

    it do
      item = build(:inquiry_node_form, notice_state: "enabled", notice_emails: valid_emails1, from_email: invalid_email)
      expect(item.valid?).to be_falsey
    end
  end
end
