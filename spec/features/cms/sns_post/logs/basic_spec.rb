require 'spec_helper'

describe "cms_pages sns post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :cms_node_page }
  let(:item) { create :cms_page, cur_node: node, state: "closed" }

  let(:edit_path) { edit_cms_page_path site.id, node, item }
  let(:index_path) { cms_sns_post_logs_path  site.id }

  let(:line_text_message) { unique_id }

  context "publish directly" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id

      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!

      login_cms_user
    end

    context "post message" do
      it "#edit" do
        capture_line_bot_client do |c1|
          capture_twitter_rest_client do |c2|
            visit edit_path
            ensure_addon_opened("#addon-cms-agents-addons-line_poster")
            within "#addon-cms-agents-addons-line_poster" do
              select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
              select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
              fill_in "item[line_text_message]", with: line_text_message
            end

            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            end
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

            expect(Cms::SnsPostLog::Twitter.count).to eq 1
            expect(Cms::SnsPostLog::Line.count).to eq 1

            visit index_path
            within ".list-items" do
              expect(page).to have_css("a", text: I18n.t("cms.options.sns_post_log_type.line"))
              expect(page).to have_css("a", text: I18n.t("cms.options.sns_post_log_type.twitter"))
            end

            # delete line log
            within ".list-items" do
              first("a", text: I18n.t("cms.options.sns_post_log_type.line")).click
            end
            expect(page).to have_link item.name
            click_on I18n.t("ss.links.delete")
            click_on I18n.t("ss.buttons.delete")
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
            expect(Cms::SnsPostLog::Twitter.count).to eq 1
            expect(Cms::SnsPostLog::Line.count).to eq 0

            # delete twitter log
            within ".list-items" do
              first("a", text: I18n.t("cms.options.sns_post_log_type.twitter")).click
            end
            expect(page).to have_link item.name
            click_on I18n.t("ss.links.delete")
            click_on I18n.t("ss.buttons.delete")
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
            expect(Cms::SnsPostLog::Twitter.count).to eq 0
            expect(Cms::SnsPostLog::Line.count).to eq 0
          end
        end
      end
    end
  end
end
