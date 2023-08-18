require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }

  let(:role_ids) { admin.gws_role_ids }
  let(:group_ids) { admin.group_ids }
  let(:user1) { create(:gws_user, group_ids: group_ids, gws_role_ids: role_ids) }
  let(:user2) { create(:gws_user, group_ids: group_ids, gws_role_ids: role_ids) }
  let(:user3) { create(:gws_user, group_ids: group_ids, gws_role_ids: role_ids) }

  let(:route_name) { unique_id }
  let!(:route) do
    create(
      :gws_workflow_route, name: route_name, group_ids: group_ids,
      approvers: [
        { "level" => 1, "user_id" => user1.id },
        { "level" => 2, "user_id" => user2.id },
        { "level" => 3, "user_id" => user3.id },
      ],
      required_counts: [ false, false, false, false, false ]
    )
  end

  let(:workflow_comment1) { unique_id }
  let(:workflow_comment2) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:approve_comment3) { unique_id }
  let(:approve_comment4) { unique_id }
  let(:remand_comment1) { unique_id }

  context "restart workflow after remanded request" do
    let(:item) { create :gws_workflow_file }
    let(:show_path) { gws_workflow_file_path(site, item, state: 'all') }

    it do
      #
      # admin: send request
      #
      login_user admin
      visit show_path

      within ".mod-workflow-request" do
        select route_name, from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")

        fill_in "workflow[comment]", with: workflow_comment1
        click_on I18n.t("workflow.buttons.request")
      end
      expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq "request"
      expect(item.state).to eq "closed"
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 1

      #
      # user1: approve request
      #
      login_user user1
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: ''})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 2

      #
      # user2: remand request
      #
      login_user user2
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment1
        click_on I18n.t("workflow.buttons.remand")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(remand_comment1)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'remand'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment1})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 3

      #
      # admin: restart request
      #
      login_user admin
      visit show_path

      within ".mod-workflow-request" do
        select I18n.t("workflow.restart_workflow"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")

        fill_in "workflow[comment]", with: workflow_comment2
        click_on I18n.t("workflow.buttons.restart")
      end
      expect(page).to have_css(".mod-workflow-view dd", text: I18n.t('workflow.state.request'))

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq "request"
      expect(item.state).to eq "closed"
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: '', file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: '', file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: '', file_ids: nil})

      expect(SS::Notification.count).to eq 4

      #
      # user1: approve request
      #
      login_user user1
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment2
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.state).to eq "closed"
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'request', comment: '', file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: '', file_ids: nil})

      expect(SS::Notification.count).to eq 5

      #
      # user2: approve request
      #
      login_user user2
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment3
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.state).to eq "closed"
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'request', comment: '', file_ids: nil})

      expect(SS::Notification.count).to eq 6

      #
      # user3: approve request, he is the last one
      #
      login_user user3
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment4
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment4)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.state).to eq "approve"
      expect(item.workflow_comment).to eq workflow_comment2
      expect(item.workflow_approvers.count).to eq 3
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment2, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment3, file_ids: nil})
      expect(item.workflow_approvers).to \
        include({level: 3, user_id: user3.id, editable: '', state: 'approve', comment: approve_comment4, file_ids: nil})

      expect(SS::Notification.count).to eq 7
    end
  end
end
