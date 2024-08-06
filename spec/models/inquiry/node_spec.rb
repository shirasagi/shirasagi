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

  context "notice_email and from_email" do
    let(:valid_email) { "sample@example.jp" }
    let(:invalid_email1) { "sample＠example.jp" }
    let(:invalid_email2) { "name <sample@example.jp>" }

    it do
      item = build(:inquiry_node_form, notice_state: "disabled", notice_email: nil, from_email: nil)
      expect(item.valid?).to be_truthy

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: nil, from_email: nil)
      expect(item.valid?).to be_falsey

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: valid_email, from_email: nil)
      expect(item.valid?).to be_falsey

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: nil, from_email: valid_email)
      expect(item.valid?).to be_falsey

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: valid_email, from_email: valid_email)
      expect(item.valid?).to be_truthy

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: invalid_email1, from_email: valid_email)
      expect(item.valid?).to be_falsey

      item = build(:inquiry_node_form, notice_state: "enabled", notice_email: invalid_email2, from_email: valid_email)
      expect(item.valid?).to be_falsey
    end
  end
end
