require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:first_line_text_message) { "first" }
  let(:second_line_text_message) { "second" }

  context "post and reset posted" do
    before do
      site.line_channel_secret = unique_id
      site.line_channel_access_token = unique_id
      site.save!
    end

    context "post message_only_carousel" do
      it "#edit" do
        capture_line_bot_client do |capture|
          login_cms_user
          visit show_path

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_no_link(I18n.t("ss.links.reset_posted"))
          end

          # first post
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: first_line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_link(I18n.t("ss.links.reset_posted"))
          end

          expect(capture.broadcast.count).to eq 1
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq first_line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1

          within "#addon-cms-agents-addons-line_poster" do
            page.accept_alert do
              click_on I18n.t("ss.links.reset_posted")
            end
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.reset_posted'))
          expect(Cms::SnsPostLog::Line.count).to eq 2

          # second post
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: second_line_text_message
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_cbox do
            have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
            click_on I18n.t("ss.buttons.ignore_alert")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_link(I18n.t("ss.links.reset_posted"))
          end

          expect(capture.broadcast.count).to eq 2
          expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
          expect(capture.broadcast.messages.dig(0, :altText)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :title)).to eq item.name
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq second_line_text_message
          expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :actions, 0, :uri)).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 3
        end
      end
    end
  end
end
