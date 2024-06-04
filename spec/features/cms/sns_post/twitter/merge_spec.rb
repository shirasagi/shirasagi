require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }

  let(:name) { "sample" }
  let(:tweet_id) { rand(100) }
  let(:username) { "user-#{unique_id}" }

  before do
    site.twitter_username = unique_id
    site.twitter_consumer_key = unique_id
    site.twitter_consumer_secret = unique_id
    site.twitter_access_token = unique_id
    site.twitter_access_token_secret = unique_id
    site.save!
  end

  context "merge and publish" do
    before { login_cms_user }

    context "post none" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.expired"), from: "item[twitter_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_css("td", text: "https://twitter.com/")
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0
        end
      end
    end

    context "post page" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("cms.options.twitter_post_format.page_only"), from: "item[twitter_post_format]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
          expect(Cms::SnsPostLog::Twitter.count).to eq 1
        end
      end

      # master page already posted
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("cms.options.twitter_post_format.page_only"), from: "item[twitter_post_format]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 1
          expect(capture.update.tweet).to include(item.name)
          expect(capture.update.tweet).to include(item.full_url)
          expect(Cms::SnsPostLog::Twitter.count).to eq 1
        end
      end
    end
  end

  context "enable edit auto post" do
    before { login_cms_user }

    context "post page" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("cms.options.twitter_post_format.page_only"), from: "item[twitter_post_format]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # second post (enable twitter_edit_auto_post)
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_post_format]"] option[selected]', text: I18n.t("cms.options.twitter_post_format.page_only"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("ss.options.state.active"), from: "item[twitter_edit_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("dd", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 2
          expect(Cms::SnsPostLog::Twitter.count).to eq 2

          # third post (disable twitter_edit_auto_post)
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
            expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            select I18n.t("ss.options.state.disabled"), from: "item[twitter_edit_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          visit show_path
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://twitter.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 2
          expect(Cms::SnsPostLog::Twitter.count).to eq 2
        end
      end
    end
  end
end
