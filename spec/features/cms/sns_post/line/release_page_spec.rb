require 'spec_helper'

describe "article_pages line post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:approve_comment) { "approve-#{unique_id}" }
  let(:line_text_message) { unique_id }
  let(:release_date) { Time.zone.at(1.day.from_now.to_i) }

  before do
    site.line_channel_secret = unique_id
    site.line_channel_access_token = unique_id
    site.save!
  end

  context "publish at release_date" do
    before { login_cms_user }

    context "post none" do
      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.broadcast.count).to eq 0
            expect(capture.broadcast.messages).to eq nil
            expect(Cms::SnsPostLog::Line.count).to eq 0
          end
        end
      end
    end

    context "post message_only_carousel" do
      it "#edit" do
        capture_line_bot_client do |capture|
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.broadcast.count).to eq 1
            expect(capture.broadcast.messages.dig(0, :template, :type)).to eq "carousel"
            expect(capture.broadcast.messages.dig(0, :template, :columns, 0, :text)).to eq line_text_message
            expect(Cms::SnsPostLog::Line.count).to eq 1
          end
        end
      end

      # master and approve
      it "#edit" do
        capture_line_bot_client do |capture|
          # create branch
          login_cms_user
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end
          expect(page).to have_link I18n.t("ss.links.edit")

          # edit
          click_on I18n.t("ss.links.edit")
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end
          first("#addon-cms-agents-addons-release_plan").click

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.draft_save")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          # send request
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_cbox_open do
              click_on I18n.t("workflow.search_approvers.index")
            end
          end

          wait_for_cbox do
            expect(page).to have_content(user1.long_name)
            wait_cbox_close do
              click_on user1.long_name
            end
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          # approve
          login_user user1
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end

          perform_enqueued_jobs do
            within ".mod-workflow-approve" do
              expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.line_post_enabled"))
              fill_in "remand[comment]", with: approve_comment
              click_on I18n.t("workflow.buttons.approve")
            end
            within "#addon-workflow-agents-addons-approver" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
              expect(page).to have_css(".index", text: approve_comment)
            end
            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.ready"))
            end
          end

          visit show_path
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-line_poster" do
            have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 0
          expect(capture.broadcast.messages).to eq nil
          expect(Cms::SnsPostLog::Line.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-workflow-agents-addons-approver" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
              expect(page).to have_css(".index", text: approve_comment)
            end
            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
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
      end
    end
  end

  context "enable edit auto post" do
    before { login_cms_user }

    context "post none" do
      it "#edit" do
        capture_line_bot_client do |capture|
          # first post
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # second post (disable line_edit_auto_post)
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.active"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
            select I18n.t("ss.options.state.disabled"), from: "item[line_edit_auto_post]"
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.broadcast.count).to eq 1
            expect(Cms::SnsPostLog::Line.count).to eq 1
          end
        end
      end
    end

    context "post message_only_carousel" do
      it "#edit" do
        capture_line_bot_client do |capture|
          # first post
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # second post (enable line_edit_auto_post)
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.active"))
            expect(page).to have_css('select[name="item[line_post_format]"] option[selected]', text: I18n.t("cms.options.line_post_format.message_only_carousel"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))
            expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            select I18n.t("ss.options.state.enabled"), from: "item[line_edit_auto_post]"
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.broadcast.count).to eq 2
            expect(Cms::SnsPostLog::Line.count).to eq 2
          end
        end
      end

      # master and approve
      it "#edit" do
        capture_line_bot_client do |capture|
          # 1. first post
          visit edit_path
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("cms.options.line_post_format.message_only_carousel"), from: "item[line_post_format]"
            fill_in "item[line_text_message]", with: line_text_message
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end

          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # 2. create branch
          login_cms_user
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            click_on I18n.t("workflow.create_branch")
            expect(page).to have_link item.name
            click_on item.name
          end
          expect(page).to have_link I18n.t("ss.links.edit")

          # 2. edit (enable line_edit_auto_post)
          click_on I18n.t("ss.links.edit")
          ensure_addon_opened("#addon-cms-agents-addons-line_poster")
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css('select[name="item[line_auto_post]"] option[selected]', text: I18n.t("ss.options.state.expired"))
            expect(page).to have_css('select[name="item[line_post_format]"] option[selected]', text: I18n.t("cms.options.line_post_format.message_only_carousel"))
            expect(page).to have_css('select[name="item[line_edit_auto_post]"] option[selected]', text: I18n.t("ss.options.state.disabled"))
            expect(find('[name="item[line_text_message]"]').value).to eq line_text_message

            select I18n.t("ss.options.state.active"), from: "item[line_auto_post]"
            select I18n.t("ss.options.state.active"), from: "item[line_edit_auto_post]"
          end

          ensure_addon_opened("#addon-cms-agents-addons-release_plan")
          within "#addon-cms-agents-addons-release_plan" do
            fill_in 'item[release_date]', with: release_date.strftime("%Y/%m/%d %H:%M")
          end
          first("#addon-cms-agents-addons-release_plan").click

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.draft_save")
            end
            expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
          end

          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          # 2. send request
          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            click_on I18n.t("workflow.search_approvers.index")
          end

          wait_for_cbox do
            expect(page).to have_content(user1.long_name)
            click_on user1.long_name
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          # 2. approve
          login_user user1
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end

          perform_enqueued_jobs do
            within ".mod-workflow-approve" do
              expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.line_post_enabled"))
              click_on I18n.t("workflow.buttons.approve")
            end
            within "#addon-workflow-agents-addons-approver" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
            end
            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.ready"))
            end
          end

          visit show_path
          within "#addon-cms-agents-addons-line_poster" do
            expect(page).to have_css("dd", text: line_text_message)
          end
          expect(capture.broadcast.count).to eq 1
          expect(Cms::SnsPostLog::Line.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user
            visit show_path

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end

            expect(capture.broadcast.count).to eq 2
            expect(Cms::SnsPostLog::Line.count).to eq 2
          end
        end
      end
    end
  end
end
