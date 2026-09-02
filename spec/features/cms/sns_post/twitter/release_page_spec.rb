require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:tweet_id) { rand(100) }
  let(:username) { "user-#{unique_id}" }

  let(:approve_comment) { "approve-#{unique_id}" }
  let(:release_date) { 1.day.from_now.beginning_of_minute }

  before do
    site.twitter_username = unique_id
    site.twitter_consumer_key = unique_id
    site.twitter_consumer_secret = unique_id
    site.twitter_access_token = unique_id
    site.twitter_access_token_secret = unique_id
    site.save!
  end

  context "publish at release_date" do
    context "post none" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          login_cms_user to: edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.expired"), from: "item[twitter_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.publish_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
            wait_for_all_ckeditors_ready
            wait_for_all_turbo_frames

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
            end
          end

          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.update.count).to eq 0
            expect(capture.update.tweet).to eq nil
            expect(Cms::SnsPostLog::Twitter.count).to eq 0
          end
        end
      end
    end

    context "post page" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          login_cms_user to: edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
            wait_for_all_ckeditors_ready
            wait_for_all_turbo_frames
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
            end
          end

          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.update.count).to eq 1
            expect(capture.update.tweet).to include(item.name)
            expect(Cms::SnsPostLog::Twitter.count).to eq 1
          end
        end
      end

      # master and approve
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          # create branch
          login_cms_user to: show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-workflow-agents-addons-branch" do
            wait_for_event_fired "turbo:frame-load" do
              click_on I18n.t("workflow.create_branch")
            end
            expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
            expect(page).to have_link item.name
            click_on item.name
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          # edit
          click_on I18n.t("ss.links.edit")
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end
            first("#addon-cms-agents-addons-release_plan").click
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.draft_save")
            end

            wait_for_notice I18n.t('ss.notice.saved')
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          # send request
          within ".mod-workflow-request" do
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            wait_for_event_fired "ajaxComplete" do
              select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
              click_on I18n.t("workflow.buttons.select")
            end
            wait_for_cbox_opened do
              click_on I18n.t("workflow.search_approvers.index")
            end
          end

          within_cbox do
            expect(page).to have_content(user1.long_name)
            wait_for_cbox_closed do
              click_on user1.long_name
            end
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready

          # approve
          login_user user1, to: show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          perform_enqueued_jobs do
            within ".mod-workflow-approve" do
              expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.twitter_post_enabled"))
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
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          visit show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_css("td", text: "https://x.com/")
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-workflow-agents-addons-approver" do
              expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
              expect(page).to have_css(".index", text: approve_comment)
            end
            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            within "#addon-cms-agents-addons-twitter_poster" do
              expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
            end
            expect(capture.update.count).to eq 1
            expect(capture.update.tweet).to include(item.name)
            expect(Cms::SnsPostLog::Twitter.count).to eq 1
          end
        end
      end
    end
  end

  context "enable edit auto post" do
    context "post none" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          # first post
          login_cms_user to: edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
              select I18n.t("ss.options.state.active"), from: "item[twitter_edit_auto_post]"
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          visit show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
          end

          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # second post (disable twitter_edit_auto_post)
          visit edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.active")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.disabled"), from: "item[twitter_edit_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end

            click_on I18n.t("ss.buttons.publish_save")
          end
          wait_for_notice I18n.t('ss.notice.saved')
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.update.count).to eq 1
            expect(Cms::SnsPostLog::Twitter.count).to eq 1
          end
        end
      end
    end

    context "post page" do
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          # first post
          login_cms_user to: edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
              select I18n.t("ss.options.state.active"), from: "item[twitter_edit_auto_post]"
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          visit show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
          end

          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # second post (enable twitter_edit_auto_post)
          visit edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.active")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.enabled"), from: "item[twitter_edit_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css('dd', text: I18n.t('ss.state.ready'))
          end
          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            expect(capture.update.count).to eq 2
            expect(Cms::SnsPostLog::Twitter.count).to eq 2
          end
        end
      end

      # master and approve
      it "#edit" do
        capture_twitter_rest_client(tweet_id: tweet_id, username: username) do |capture|
          # 1. first post
          login_cms_user to: edit_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
              select I18n.t("ss.options.state.active"), from: "item[twitter_edit_auto_post]"
            end
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              wait_for_cbox_opened { click_on I18n.t("ss.buttons.publish_save") }
            end
            within_cbox do
              expect(page).to have_css("#alertExplanation", text: I18n.t("cms.confirm.twitter_post_enabled"))
              click_on I18n.t("ss.buttons.ignore_alert")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          visit show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
          end

          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # 2. create branch
          login_cms_user to: show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-workflow-agents-addons-branch" do
            wait_for_event_fired "turbo:frame-load" do
              click_on I18n.t("workflow.create_branch")
            end
            expect(page).to have_css('.see.branch', text: I18n.t("workflow.notice.created_branch_page"))
            expect(page).to have_link item.name
            click_on item.name
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          # 2. edit (enable twitter_edit_auto_post)
          click_on I18n.t("ss.links.edit")
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          within "form#item-form" do
            ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
            within "#addon-cms-agents-addons-twitter_poster" do
              expected = I18n.t("ss.options.state.expired")
              expect(page).to have_css('select[name="item[twitter_auto_post]"] option[selected]', text: expected)
              expected = I18n.t("ss.options.state.disabled")
              expect(page).to have_css('select[name="item[twitter_edit_auto_post]"] option[selected]', text: expected)

              select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
              select I18n.t("ss.options.state.active"), from: "item[twitter_edit_auto_post]"
            end

            ensure_addon_opened("#addon-cms-agents-addons-release_plan")
            within "#addon-cms-agents-addons-release_plan" do
              fill_in_datetime 'item[release_date]', with: release_date
            end
            first("#addon-cms-agents-addons-release_plan").click
          end

          perform_enqueued_jobs do
            within "form#item-form" do
              click_on I18n.t("ss.buttons.draft_save")
            end
            wait_for_notice I18n.t('ss.notice.saved')
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          # 2. send request
          within ".mod-workflow-request" do
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            wait_for_event_fired "ajaxComplete" do
              select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
              click_on I18n.t("workflow.buttons.select")
            end
            wait_for_js_ready

            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user1.long_name)
            wait_for_cbox_closed { click_on user1.long_name }
          end
          within ".mod-workflow-request" do
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready

          # 2. approve
          login_user user1, to: show_path
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          perform_enqueued_jobs do
            within ".mod-workflow-approve" do
              expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.twitter_post_enabled"))
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
          wait_for_all_turbo_frames
          wait_for_all_ckeditors_ready
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
          end
          expect(capture.update.count).to eq 1
          expect(Cms::SnsPostLog::Twitter.count).to eq 1

          Timecop.travel(release_date) do
            job = Cms::Page::ReleaseJob.bind(site_id: node.site_id, node_id: node.id)
            perform_enqueued_jobs do
              expect { job.perform_now }.to output.to_stdout
            end

            login_cms_user to: show_path
            wait_for_all_turbo_frames
            wait_for_all_ckeditors_ready
            expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

            within "#addon-cms-agents-addons-release" do
              expect(page).to have_css('dd', text: I18n.t('ss.options.state.public'))
            end
            within "#addon-cms-agents-addons-twitter_poster" do
              expect(page).to have_css("td", text: "https://x.com/#{username}/status/#{tweet_id}")
            end
            expect(capture.update.count).to eq 2
            expect(Cms::SnsPostLog::Twitter.count).to eq 2
          end
        end
      end
    end
  end
end
