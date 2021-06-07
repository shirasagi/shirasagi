require 'spec_helper'

describe "article_pages twitter post", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :article_node_page }
  let(:item) { create :article_page, cur_node: node, state: "closed" }

  let(:user) { cms_user }
  let!(:user1) { create(:cms_test_user, group_ids: user.group_ids, cms_role_ids: user.cms_role_ids) }

  let(:show_path) { article_page_path site.id, node, item }
  let(:edit_path) { edit_article_page_path site.id, node, item }

  let(:line_text_message) { unique_id }

  context "approve and publish" do
    before do
      site.twitter_username = unique_id
      site.twitter_consumer_key = unique_id
      site.twitter_consumer_secret = unique_id
      site.twitter_access_token = unique_id
      site.twitter_access_token_secret = unique_id
      site.save!
    end

    context "post none" do
      it "#edit" do
        capture_twitter_rest_client do |capture|
          # edit
          login_cms_user
          visit edit_path

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.expired"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
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

          # send request
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

          # approve
          login_user user1
          visit show_path
          within ".mod-workflow-approve" do
            expect(page).to have_no_css(".sns-post-confirm", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          login_cms_user
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
          # edit
          login_cms_user
          visit edit_path

          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          # send request
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

          # approve
          login_user user1
          visit show_path
          within ".mod-workflow-approve" do
            expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          login_cms_user
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

      # with branch page
      it "#edit" do
        capture_twitter_rest_client do |capture|
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
          ensure_addon_opened("#addon-cms-agents-addons-twitter_poster")
          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_css("select option[selected]", text: I18n.t("ss.options.state.expired"))
            select I18n.t("ss.options.state.active"), from: "item[twitter_auto_post]"
          end
          within "form#item-form" do
            click_on I18n.t("ss.buttons.draft_save")
          end
          expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

          within "#addon-cms-agents-addons-twitter_poster" do
            expect(page).to have_no_css("dd", text: "https://twitter.com/user_screen_id/status/twitter_id")
          end
          expect(capture.update.count).to eq 0
          expect(capture.update.tweet).to eq nil
          expect(capture.update_with_media.count).to eq 0
          expect(capture.update_with_media.tweet).to eq nil
          expect(Cms::SnsPostLog::Twitter.count).to eq 0

          # send request
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

          # approve
          login_user user1
          visit show_path
          within "#addon-workflow-agents-addons-branch" do
            expect(page).to have_link item.name
            click_on item.name
          end

          within ".mod-workflow-approve" do
            expect(page).to have_css(".sns-post-confirm", text: I18n.t("cms.confirm.twitter_post_enabled"))
            click_on I18n.t("workflow.buttons.approve")
          end
          within "#addon-workflow-agents-addons-approver" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.approve"))
          end
          within "#addon-cms-agents-addons-release" do
            expect(page).to have_css("dd", text: I18n.t("ss.options.state.public"))
          end

          login_cms_user
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
