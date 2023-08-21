require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  context "twitter token disabled" do
    before do
      site.twitter_poster_state = "enabled"
      site.twitter_username = nil
      site.twitter_consumer_key = nil
      site.twitter_consumer_secret = nil
      site.twitter_access_token = nil
      site.twitter_access_token_secret = nil
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_no_css "#addon-cms-agents-addons-twitter_poster"
    end
  end

  context "twitter poster disabled" do
    before do
      site.twitter_poster_state = "disabled"
      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_no_css "#addon-cms-agents-addons-twitter_poster"
    end
  end

  context "twitter poster enabled" do
    before do
      site.twitter_poster_state = "enabled"
      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!
      login_cms_user
    end

    it do
      visit edit_path
      expect(page).to have_css "#addon-basic"
      expect(page).to have_css "#addon-cms-agents-addons-twitter_poster"
    end
  end
end
