require 'spec_helper'

describe "edit requested page", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let!(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  # let!(:user2) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:workflow_comment) { unique_id }
  let(:approve_comment) { "approve-#{unique_id}" }
  let(:remand_comment) { "remand-#{unique_id}" }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "with article/page" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }
    let(:show_path) { article_page_path(site, node, item) }

    context "when all users approve request" do
      it do
        expect(item.backups.count).to eq 1

        #
        # admin: send request
        #
        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 2

        #
        # user1: edit requested page
        #
        login_user user1, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("ss.links.edit")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within "#item-form" do
          fill_in_ckeditor "item[html]", with: unique_id
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.backups.count).to eq 3
      end
    end
  end

  context "with article/page with accessibility errors" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let(:html_with_accessibility_error) do
      <<~HTML
        <div>
          <img src="/image.jpg">
        </div>
      HTML
    end
    let!(:item) do
      create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id,
            html: html_with_accessibility_error, state: "closed")
    end
    let(:show_path) { article_page_path(site, node, item) }

    # アクセシビリティチェックを無視して保存する権限がある場合、公開承認ボタンが表示される
    context "when user with permission approves" do
      it do
        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})

        login_user user1, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(page).to have_button(I18n.t("workflow.buttons.approve"))
        expect(page).to have_content(I18n.t("errors.messages.check_html"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_js_ready
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("article.page_navi.back_to_index")
        expect(page).to have_content(item.name)
        expect(page).to have_content(I18n.t("ss.state.public"))
      end
    end

    # アクセシビリティエラーがある記事の公開承認を試みた場合、承認ボタンが表示されず、差し戻しのみ可能
    context "when user without permission attempts to approve" do
      it do
        role = cms_role
        role.update(permissions: (role.permissions - %w(edit_cms_ignore_syntax_check)))
        role.reload

        # 申請処理
        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})

        login_user user1, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(page).to have_content(I18n.t("errors.messages.accessibility_check_required"))
        expect(page).not_to have_button(I18n.t("workflow.buttons.approve"))
        expect(page).to have_button(I18n.t("workflow.buttons.remand"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment
          click_on I18n.t("workflow.buttons.remand")
        end
        wait_for_js_ready
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("article.page_navi.back_to_index")
        expect(page).to have_content(item.name)
        expect(page).to have_content(I18n.t("workflow.state.remand"))
      end
    end

    # 権限がないユーザーでも「非公開」承認は可能であること
    context "when user without permission approves for closed" do
      it do
        role = cms_role
        role.update(permissions: (role.permissions - %w(edit_cms_ignore_syntax_check)))
        role.reload

        item.update!(state: "public")

        # 申請処理（非公開申請）
        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "public"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})

        # 承認者としてログイン
        login_user user1, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        # 非公開申請の場合は承認ボタンが表示され、承認できる
        expect(page).to have_button(I18n.t("workflow.buttons.approve"))
        expect(page).to have_content(I18n.t("errors.messages.check_html"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_js_ready
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("article.page_navi.back_to_index")
        expect(page).to have_content(item.name)
        expect(page).to have_content(I18n.t("ss.state.closed"))
      end
    end
  end

  context "with branch page with accessibility errors" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let(:html_with_accessibility_error) do
      <<~HTML
        <div>
          <img src="/image.jpg">
        </div>
      HTML
    end
    let!(:original_item) do
      create(
        :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html_with_accessibility_error,
        state: "closed")
    end
    let(:show_path) { article_page_path(site, node, original_item) }

    # 権限ありの場合、差し替えページも承認できる
    context "when user with permission approves branch" do
      it do
        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#addon-workflow-agents-addons-branch" do
          wait_for_event_fired("turbo:frame-load") { click_on I18n.t('workflow.create_branch') }
          expect(page).to have_content(original_item.name)
          click_on original_item.name
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.links.edit')
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        within "form#item-form" do
          fill_in "item[name]", with: "replacement"
          click_button I18n.t('ss.buttons.draft_save')
        end
        within_cbox do
          expect(page).to have_css("#alertExplanation", text: I18n.t('cms.syntax_check'))
          expect(page).to have_css("#alertExplanation", text: I18n.t("errors.messages.set_img_alt"))
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        branch_item = Cms::Page.last
        branch_path = article_page_path(site, node, branch_item)

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        branch_item.reload
        expect(branch_item.workflow_user_id).to eq cms_user.id
        expect(branch_item.workflow_state).to eq "request"
        expect(branch_item.state).to eq "closed"
        expect(branch_item.workflow_comment).to eq workflow_comment
        expect(branch_item.workflow_approvers.count).to eq 1
        expect(branch_item.workflow_approvers).to include(
          { level: 1, user_id: user1.id, editable: '', state: 'request', comment: '' })

        login_user user1, to: branch_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(page).to have_button(I18n.t("workflow.buttons.approve"))
        expect(page).to have_content(I18n.t("errors.messages.check_html"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_js_ready
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("article.page_navi.back_to_index")
        expect(page).to have_content(branch_item.name)
        expect(page).to have_content(I18n.t("ss.state.public"))
      end
    end

    # 権限なしの場合、差し替えページの承認ボタンは表示されず、差し戻しのみ可能
    context "when user without permission attempts to approve branch" do
      let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
      let(:html_with_accessibility_error) do
        <<~HTML
          <div>
            <img src="/image.jpg">
          </div>
        HTML
      end
      let!(:original_item) do
        create(
          :article_page, cur_site: site, cur_node: node, layout_id: layout.id, html: html_with_accessibility_error,
          state: "closed")
      end
      let(:show_path) { article_page_path(site, node, original_item) }
      it do

        login_user cms_user, to: show_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        within "#addon-workflow-agents-addons-branch" do
          wait_for_event_fired("turbo:frame-load") { click_on I18n.t('workflow.create_branch') }
          expect(page).to have_content(original_item.name)
          click_on original_item.name
        end
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t('ss.links.edit')
        within "form#item-form" do
          fill_in "item[name]", with: "replacement"
          click_button I18n.t('ss.buttons.draft_save')
        end
        within_cbox do
          expect(page).to have_css(".errorExplanation", text: I18n.t("errors.messages.set_img_alt"))
          click_on I18n.t("ss.buttons.ignore_alert")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames
        branch_item = Cms::Page.last
        branch_path = article_page_path(site, node, branch_item)

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_for_cbox_opened do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        within_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_for_cbox_closed do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        branch_item.reload
        expect(branch_item.workflow_user_id).to eq cms_user.id
        expect(branch_item.workflow_state).to eq "request"
        expect(branch_item.state).to eq "closed"
        expect(branch_item.workflow_comment).to eq workflow_comment
        expect(branch_item.workflow_approvers.count).to eq 1
        expect(branch_item.workflow_approvers).to include(
          { level: 1, user_id: user1.id, editable: '', state: 'request', comment: '' })

        role = cms_role
        role.update(permissions: (role.permissions - %w(edit_cms_ignore_syntax_check)))
        role.reload
        login_user user1, to: branch_path
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        expect(page).to have_content(I18n.t("errors.messages.accessibility_check_required"))
        expect(page).not_to have_button(I18n.t("workflow.buttons.approve"))
        expect(page).to have_button(I18n.t("workflow.buttons.remand"))

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment
          click_on I18n.t("workflow.buttons.remand")
        end
        wait_for_js_ready
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment)
        wait_for_all_ckeditors_ready
        wait_for_all_turbo_frames

        click_on I18n.t("article.page_navi.back_to_index")
        expect(page).to have_content(branch_item.name)
        expect(page).to have_content(I18n.t("workflow.state.remand"))
      end
    end
  end
end
