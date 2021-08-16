require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:first_name) { "first" }
  let(:second_name) { "second" }

  context "post and reset posted" do
    before do
      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!

      login_cms_user
    end

    context "post page" do
      it "#edit" do
        capture_twitter_rest_client do |capture|
          login_cms_user
          visit show_path

          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_link(I18n.t("ss.links.reset_posted"))
          end

          # first post
          visit edit_path
          within "form#item-form" do
            fill_in "item[name]", with: first_name
          end
          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("cms.options.twitter_post_format.page_only"), from: "item[twitter_post_format]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_link(I18n.t("ss.links.reset_posted"))
          end

          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(first_name)
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          within "#addon-cms-agents-addons-twitter_poster" do
            page.accept_alert do
              click_on I18n.t("ss.links.reset_posted")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.reset_posted'))
          expect(Cms::SnsPostLog::Twitter.count).to eq 2

          # second post
          visit edit_path
          within "form#item-form" do
            fill_in "item[name]", with: second_name
          end
          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("cms.options.twitter_post_format.page_only"), from: "item[twitter_post_format]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_link(I18n.t("ss.links.reset_posted"))
          end

          expect(capture.update.count).to eq 2
          expect(capture.update.tweet).to include(second_name)
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 3
        end
      end
    end
  end
end
