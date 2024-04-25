require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:new_path) { new_article_page_path site.id, node }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:name) { "sample" }
  let(:line_text_message) { unique_id }

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  context "publish directly" do
    before { login_cms_user }

    context "post none" do
      it "#new" do
        capture_line_bot_client do |capture|
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
          end
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.expired"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0
        end
      end

      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.expired"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.expired"))
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0
        end
      end
    end

    context "post message_only_carousel" do
      it "#new" do
        capture_line_bot_client do |capture|
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
          end
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq name
          expect(name).to eq name
          expect(message).to eq line_text_message
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end

      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)
          url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :footer, :contents, 0, :action, :uri)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq item.name
          expect(name).to eq item.name
          expect(message).to eq line_text_message
          expect(url).to eq item.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end
    end

    context "post thumb_carousel" do
      let!(:file) do
        tmp_ss_file(
          Cms::TempFile, contents: "#{Rails.root}/spec/fixtures/ss/logo.png", user: user, site: site, node: node
        )
      end

      it "#new" do
        capture_line_bot_client do |capture|
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
          end

          within "#addon-cms-agents-addons-thumb" do
            wait_cbox_open do
              first(".btn-file-upload").click
            end
          end
          within_cbox do
            expect(page).to have_css(".file-view", text: file.name)
            wait_cbox_close do
              click_on file.name
            end
          end

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text:
              I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.thumb_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)
          hero_url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :hero, :url)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq name
          expect(name).to eq name
          expect(message).to eq line_text_message
          expect(hero_url).to eq file.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end

      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          within "#addon-cms-agents-addons-thumb" do
            wait_cbox_open do
              first(".btn-file-upload").click
            end
          end
          within_cbox do
            expect(page).to have_css(".file-view", text: file.name)
            wait_cbox_close do
              click_on file.name
            end
          end

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.thumb_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)
          url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :footer, :contents, 0, :action, :uri)
          hero_url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :hero, :url)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq item.name
          expect(name).to eq item.name
          expect(message).to eq line_text_message
          expect(url).to eq item.full_url
          expect(hero_url).to eq file.full_url
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end
    end

    context "post body_carousel" do
      let(:attach_file_path) { "#{Rails.root}/spec/fixtures/ss/file/keyvisual.gif" }

      it "#new" do
        capture_line_bot_client do |capture|
          visit new_path
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "#addon-cms-agents-addons-file" do
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
          within_cbox do
            attach_file "item[in_files][]", attach_file_path
            wait_cbox_close do
              click_button I18n.t("ss.buttons.attach")
            end
          end
          within '#selected-files' do
            click_on I18n.t("sns.image_paste")
          end

          within "form#item-form" do
            fill_in "item[name]", with: name
          end
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.body_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)
          hero_url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :hero, :url)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq name
          expect(name).to eq name
          expect(message).to eq line_text_message
          expect(hero_url).to end_with File.basename(attach_file_path)
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end

      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-file")
          within "#addon-cms-agents-addons-file" do
            wait_cbox_open do
              click_on I18n.t("ss.buttons.upload")
            end
          end
          within_cbox do
            attach_file "item[in_files][]", attach_file_path
            wait_cbox_close do
              click_button I18n.t("ss.buttons.attach")
            end
          end
          within '#selected-files' do
            click_on I18n.t("sns.image_paste")
          end

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.body_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open do
                click_on I18n.t("ss.buttons.publish_save")
              end
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)
          url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :footer, :contents, 0, :action, :uri)
          hero_url = capture.broadcast.messages.dig(0, :contents, :contents, 0, :hero, :url)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq item.name
          expect(name).to eq item.name
          expect(message).to eq line_text_message
          expect(url).to eq item.full_url
          expect(hero_url).to end_with File.basename(attach_file_path)
          expect(Cms::SnsPostLog::Line.count).to eq 1
        end
      end
    end
  end

  context "enable edit auto post" do
    before { login_cms_user }

    context "post message_only_carousel" do
      it "#new" do
        capture_line_bot_client do |capture|
          visit new_path
          within "form#item-form" do
            fill_in "item[name]", with: name
          end
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            select I18n.t("ss.options.state.enabled"), from: "item[line_edit_auto_post]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          type = capture.broadcast.messages.dig(0, :contents, :type)
          alt = capture.broadcast.messages.dig(0, :altText)
          name = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 0, :text)
          message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)

          expect(capture.broadcast.count).to eq 1
          expect(type).to eq "carousel"
          expect(alt).to eq name
          expect(name).to eq name
          expect(message).to eq line_text_message
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # edit (enable line_edit_auto_post)
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.active"))
            expect(page).to have_css('select[name="item[line_post_format]"] option[selected]',
              text: I18n.t("cms.options.line_post_format.message_only_carousel"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))
            expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

            select I18n.t("ss.options.state.enabled"), from: "item[line_edit_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          expect(capture.broadcast.count).to eq 2
          expect(Cms::SnsPostLog::Line.count).to eq 2

          # edit (disable line_edit_auto_post)
          click_on I18n.t("ss.links.edit")

          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.active"))
            expect(page).to have_css('select[name="item[line_post_format]"] option[selected]',
              text: I18n.t("cms.options.line_post_format.message_only_carousel"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
              text: I18n.t("ss.options.state.disabled"))
            expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

            select I18n.t("ss.options.state.disabled"), from: "item[line_edit_auto_post]"
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          expect(capture.broadcast.count).to eq 2
          expect(Cms::SnsPostLog::Line.count).to eq 2
        end
      end
    end
  end
end
