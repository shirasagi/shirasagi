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
    end

    context "merge and publish" do
      before { login_cms_user }

      context "post none" do
        it "#edit" do
          capture_line_bot_client do |capture|
            visit show_path
            expect(page).to have_css("#workflow_route",
              text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end
            expect(page).to have_css("#workflow_route",
              text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

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
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
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
        it "#edit" do
          capture_line_bot_client do |capture|
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

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
                wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
              end
              wait_for_cbox do
                expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
                click_on I18n.t("ss.buttons.ignore_alert")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
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

        # master page already posted
        it "#edit" do
          capture_line_bot_client do |capture|
            # first post
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

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
            within "form#item-form" do
              wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
            end

            perform_enqueued_jobs do
              wait_for_cbox do
                expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
                click_on I18n.t("ss.buttons.ignore_alert")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
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

            # second post
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

            ensure_addon_opened("#addon-cms-agents-addons-line_poster")
            within "#addon-cms-agents-addons-line_poster" do
              expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.expired"))
              expect(page).to have_css('select[name="item[line_post_format]"] option[selected]',
                text: I18n.t("cms.options.line_post_format.message_only_carousel"))
              expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.disabled"))
              expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

              select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
              fill_in "item[line_text_message]", with: "modified"
            end

            perform_enqueued_jobs do
              within "form#item-form" do
                click_on I18n.t("ss.buttons.publish_save")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
            within "#addon-cms-agents-addons-line_poster" do
              expect(page).to have_css("dd", text: "modified")
            end

            type = capture.broadcast.messages.dig(0, :contents, :type)
            message = capture.broadcast.messages.dig(0, :contents, :contents, 0, :body, :contents, 1, :text)

            expect(capture.broadcast.count).to eq 1
            expect(type).to eq "carousel"
            expect(message).to eq line_text_message
            expect(Cms::SnsPostLog::Line.count).to eq 1
          end
        end
      end
    end

    context "enable edit auto post" do
      before { login_cms_user }

      context "post message_only_carousel" do
        it "#edit" do
          capture_line_bot_client do |capture|
            # first post
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

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
              wait_for_cbox do
                expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
                click_on I18n.t("ss.buttons.ignore_alert")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
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

            # second post (enable line_edit_auto_post)
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

            ensure_addon_opened("#addon-cms-agents-addons-line_poster")
            within "#addon-cms-agents-addons-line_poster" do
              expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.expired"))
              expect(page).to have_css('select[name="item[line_post_format]"] option[selected]',
                text: I18n.t("cms.options.line_post_format.message_only_carousel"))
              expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.disabled"))
              expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

              select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
              select I18n.t("ss.options.state.enabled"), from: "item[line_edit_auto_post]"
            end

            perform_enqueued_jobs do
              within "form#item-form" do
                wait_cbox_open { click_on I18n.t("ss.buttons.publish_save") }
              end
              wait_for_cbox do
                expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
                click_on I18n.t("ss.buttons.ignore_alert")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
            within "#addon-cms-agents-addons-line_poster" do
              expect(page).to have_css("dd", text: line_text_message)
            end
            expect(capture.broadcast.count).to eq 2
            expect(Cms::SnsPostLog::Line.count).to eq 2

            # third post (disable line_edit_auto_post)
            visit show_path
            within "#addon-workflow-agents-addons-branch" do
              wait_for_turbo_frame "#workflow-branch-frame"
              wait_event_to_fire "turbo:frame-load" do
                click_on I18n.t("workflow.create_branch")
              end
              expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
              expect(page).to have_link item.name
              click_on item.name
            end

            expect(page).to have_link I18n.t("ss.links.edit")
            click_on I18n.t("ss.links.edit")

            ensure_addon_opened("#addon-cms-agents-addons-line_poster")
            within "#addon-cms-agents-addons-line_poster" do
              expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.expired"))
              expect(page).to have_css('select[name="item[line_post_format]"] option[selected]',
                text: I18n.t("cms.options.line_post_format.message_only_carousel"))
              expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]',
                text: I18n.t("ss.options.state.disabled"))
              expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

              select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
              select I18n.t("ss.options.state.disabled"), from: "item[line_edit_auto_post]"
            end

            perform_enqueued_jobs do
              within "form#item-form" do
                click_on I18n.t("ss.buttons.publish_save")
              end
              expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
            end

            visit show_path
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
end
