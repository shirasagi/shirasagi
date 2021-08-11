require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:new_path) { new_article_page_path site.id, node }
  let(:show_path) { article_page_path site.id, node, item }

  let(:name) { "sample" }
  let(:line_text_message) { unique_id }

  context "merge and publish" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!

      login_cms_user
    end

    context "post none" do
      it "#edit" do
        capture_line_bot_client do |capture|
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.expired"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0
        end
      end
    end

    context "post message_only_carousel" do
      it "#edit" do
        capture_line_bot_client do |capture|
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end

      # master page already posted
      it "#edit" do
        capture_line_bot_client do |capture|
          # first post
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # second post
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end

          expect(page).to have_link I18n.t("ss.links.edit")
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            fill_in "item[line_text_message]", with: "modified"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: "modified")
          end
          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end
    end
  end
end
