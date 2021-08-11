require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }

  let(:name) { "sample" }

  context "merge and publish" do
    before do
      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!

      login_cms_user
    end

    context "post none" do
      it "#edit" do
        capture_twitter_rest_client do |capture|
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.expired"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0
        end
      end
    end

    context "post message" do
      it "#edit" do
        capture_twitter_rest_client do |capture|
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 1
        end
      end

      # master page already posted
      it "#edit" do
        capture_twitter_rest_client do |capture|
          # first post
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # second post
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 1
        end
      end
    end
  end
end
