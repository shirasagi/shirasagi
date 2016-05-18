require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  describe "#attributes" do
    subject(:item) { create :article_page, cur_node: node }

    it { expect(item.becomes_with_route).not_to be_nil }
    it { expect(item.dirname).to eq node.filename }
    it { expect(item.basename).not_to be_nil }
    it { expect(item.path).not_to be_nil }
    it { expect(item.url).not_to be_nil }
    it { expect(item.full_url).not_to be_nil }
    it { expect(item.parent).to eq node }
  end

  describe "shirasagi-442" do
    subject { create :article_page, cur_node: node, html: "   <p>あ。&rarr;い</p>\r\n   " }
    its(:summary) { is_expected.to eq "あ。→い" }
  end

  describe "#email_for_gravatar" do
    let!(:item) { build :article_page, cur_node: node, gravatar_email: 'gravatar@example.jp' }

    it do
      item.gravatar_image_view_kind = nil
      expect(item.email_for_gravatar).to be_nil
    end

    it do
      item.gravatar_image_view_kind = 'disable'
      expect(item.email_for_gravatar).to be_nil
    end

    it do
      item.gravatar_image_view_kind = 'cms_user_email'
      expect(item.email_for_gravatar).to eq item.user.email
    end

    it do
      item.gravatar_image_view_kind = 'special_email'
      expect(item.email_for_gravatar).to eq item.gravatar_email
    end
  end
end
