require 'spec_helper'

describe Article::Page, dbscope: :example do
  let(:node) { create :article_node_page }

  describe "#email_for_gravatar" do
    let!(:item) { create :article_page, cur_node: node, gravatar_email: 'gravatar@example.jp' }

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
