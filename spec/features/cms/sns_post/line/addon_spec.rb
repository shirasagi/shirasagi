require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "line token disabled" do
    before do
      site.line_poster_state = "enabled"
      site.line_channel_secret = nil
      site.line_channel_access_token = nil
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_no_css "#addon-cms-agents-addons-line_poster"
    end
  end

  context "line poster disabled" do
    before do
      site.line_poster_state = "disabled"
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_no_css "#addon-cms-agents-addons-line_poster"
    end
  end

  context "line poster enabled" do
    before do
      site.line_poster_state = "enabled"
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_css "#addon-cms-agents-addons-line_poster"
    end
  end
end
