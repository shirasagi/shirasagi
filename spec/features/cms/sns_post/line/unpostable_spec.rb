require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }

  let(:new_path) { new_article_page_path site.id, node }

  let(:name) { "sample" }
  let(:line_text_message) { unique_id }

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  context "upload policy enabled" do
    before { login_cms_user }

    before do
      upload_policy_before_settings('sanitizer')
    end

    after do
      upload_policy_after_settings
    end

    context "post none" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
        end
        ensure_addon_opened("#addon-cms-agents-addons-line_poster")
        within "#addon-cms-agents-addons-line_poster" do
          select I18n.t("ss.options.state.expired"), from: "item[line_auto_post]"
          select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
          fill_in "item[line_text_message]", with: line_text_message
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.publish_save")
        end
        wait_for_notice I18n.t('ss.notice.saved')
        expect(enqueued_jobs.size).to eq 0
      end
    end

    context "post message_only_carousel" do
      it "#new" do
        visit new_path
        within "form#item-form" do
          fill_in "item[name]", with: name
        end
        ensure_addon_opened("#addon-cms-agents-addons-line_poster")
        within "#addon-cms-agents-addons-line_poster" do
          select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
          select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
          fill_in "item[line_text_message]", with: line_text_message
        end
        within "form#item-form" do
          wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
        end
        within_cbox do
          expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        expect(page).to have_css(".errorExplanation",
          text: I18n.t("errors.messages.denied_with_upload_policy", policy: I18n.t("ss.options.upload_policy.sanitizer")))
        expect(enqueued_jobs.size).to eq 0
      end
    end
  end
end
