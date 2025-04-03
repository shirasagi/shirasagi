require 'spec_helper'

describe "back_to_previous route", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user2) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user3) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user4) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:user5) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:route_name) { unique_id }
  let(:workflow_comment) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:approve_comment3) { unique_id }
  let(:approve_comment4) { unique_id }
  let(:remand_comment1) { unique_id }
  let(:remand_comment2) { unique_id }
  let(:remand_comment3) { unique_id }

  let!(:route) do
    create(
      :workflow_route, name: route_name, on_remand: 'back_to_previous',
      approvers: [
        { "level" => 1, "user_id" => user1.id },
        { "level" => 2, "user_id" => user2.id },
        { "level" => 3, "user_id" => user3.id },
      ],
      required_counts: [ false, false, false, false, false ]
    )
  end

  context "with article/page" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }
    let(:show_path) { article_page_path(site, node, item) }

    context "finally approve request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
        end
        wait_for_js_ready
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 1

        #
        # user1: approve request
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: remand request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment1})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user1: approve request again
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 4

        #
        # user2: approve request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 5

        #
        # user3: approve request
        #
        login_user user3
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment4
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment4)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'approve', comment: approve_comment4})

        expect(Sys::MailLog.count).to eq 6
      end
    end

    context "finally remand request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
        end
        wait_for_js_ready
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 1

        #
        # user1: approve request
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: approve request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user3: remand request
        #
        login_user user3
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment3
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ""})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 4

        #
        # user2: remand request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment2
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ""})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 5

        #
        # user1: remand request; first user remand a request then document workflow status goes to remand
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.remand"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'remand', comment: remand_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 6
      end
    end
  end

  context "with cms/page at root" do
    let!(:item) { create(:cms_page, cur_site: site, layout_id: layout.id, state: 'closed') }
    let(:show_path) { cms_page_path(site, item) }

    context "finally approve request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
        end
        wait_for_js_ready
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 1

        #
        # user1: approve request
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: remand request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment1})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user1: approve request again
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 4

        #
        # user2: approve request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 5

        #
        # user3: approve request
        #
        login_user user3
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment4
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.approve"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment3)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment4)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'approve', comment: approve_comment4})

        expect(Sys::MailLog.count).to eq 6
      end
    end

    context "finally remand request" do
      it do
        login_cms_user
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
        end
        wait_for_js_ready
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 1

        #
        # user1: approve request
        #
        login_user user1
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: approve request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[2]).to include({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user3: remand request
        #
        login_user user3
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment2)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment3
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ""})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 4

        #
        # user2: remand request
        #
        login_user user2
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: approve_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment2
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ""})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 5

        #
        # user1: remand request; first user remand a request then document workflow status goes to remand
        #
        login_user user1
        visit show_path
        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        wait_for_all_turbo_frames
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.remand"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment1)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment2)
        expect(page).to have_css(".mod-workflow-view dd", text: remand_comment3)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'remand', comment: remand_comment1})
        expect(item.workflow_approvers[1]).to \
          include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2})
        expect(item.workflow_approvers[2]).to \
          include({level: 3, user_id: user3.id, editable: '', state: 'remand', comment: remand_comment3})

        expect(Sys::MailLog.count).to eq 6
      end
    end
  end
end
