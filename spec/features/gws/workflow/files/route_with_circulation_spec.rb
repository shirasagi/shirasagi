require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  context "my group with circulation step" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let!(:user1) do
      Gws::User.create name: "一般ユーザー1", uid: "user1", email: "user1@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let!(:user2) do
      Gws::User.create name: "一般ユーザー2", uid: "user2", email: "user2@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let!(:user3) do
      Gws::User.create name: "一般ユーザー3", uid: "user3", email: "user3@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end
    let!(:user4) do
      Gws::User.create name: "一般ユーザー4", uid: "user4", email: "user4@example.jp", in_password: "pass",
        group_ids: [ admin.groups.first.id ], gws_role_ids: [ Gws::Role.first.id ]
    end

    let(:route_name) { unique_id }
    let!(:route) do
      create(
        :gws_workflow_route, name: route_name, group_ids: admin.group_ids,
        approvers: [
          { "level" => 1, "user_id" => user1.id },
        ],
        required_counts: [ false, false, false, false, false ],
        circulations: [
          { "level" => 1, "user_id" => user2.id },
          { "level" => 1, "user_id" => user3.id },
          { "level" => 2, "user_id" => user4.id },
        ]
      )
    end

    let(:item) { create :gws_workflow_file }
    let(:show_path) { gws_workflow_file_path(site, item, state: 'all') }

    let(:workflow_comment1) { unique_id }
    let(:approve_comment1) { unique_id }
    let(:circulation_comment2) { unique_id }
    let(:circulation_comment3) { unique_id }
    let(:circulation_comment4) { unique_id }

    it do
      #
      # admin: 申請する（承認者 1 段、1 名＋回覧者 2 段、3 名）
      #
      login_gws_user
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
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user2.id, state: 'pending', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user3.id, state: 'pending', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: item.name)
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user1.id]
        expect(memo.text).to eq ""
      end

      #
      # user1: 申請を承認する
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
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user2.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user3.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).second.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: item.name)
        expect(memo.user_id).to eq user1.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.text).to eq ""
      end
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
        expect(memo.user_id).to eq user1.id
        expect(memo.member_ids).to eq [user2.id, user3.id]
        expect(memo.text).to eq ""
      end

      #
      # user2: 申請を確認する
      #
      login_user user2
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: circulation_comment2
        click_on I18n.t("workflow.links.set_seen")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(circulation_comment2)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user3.id, state: 'unseen', comment: ''})
      expect(item.workflow_circulations).to \
        include({level: 2, user_id: user4.id, state: 'pending', comment: ''})

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.user_id).to eq user2.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.text).to eq ""
      end

      #
      # user3: 申請を確認する
      #
      login_user user3
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: circulation_comment3
        click_on I18n.t("workflow.links.set_seen")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(circulation_comment3)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user3.id, state: 'seen', comment: circulation_comment3})
      expect(item.workflow_circulations).to \
        include({level: 2, user_id: user4.id, state: 'unseen', comment: ''})

      expect(SS::Notification.count).to eq 6
      SS::Notification.order_by(id: -1).second.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.user_id).to eq user3.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.text).to eq ""
      end
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: item.name)
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user4.id]
        expect(memo.text).to eq ""
      end

      #
      # user4: 申請を確認する
      #
      login_user user4
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: circulation_comment4
        click_on I18n.t("workflow.links.set_seen")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(circulation_comment4)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment1
      expect(item.workflow_approvers.count).to eq 1
      expect(item.workflow_approvers).to \
        include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
      expect(item.workflow_circulations.count).to eq 3
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user2.id, state: 'seen', comment: circulation_comment2})
      expect(item.workflow_circulations).to \
        include({level: 1, user_id: user3.id, state: 'seen', comment: circulation_comment3})
      expect(item.workflow_circulations).to \
        include({level: 2, user_id: user4.id, state: 'seen', comment: circulation_comment4})

      expect(SS::Notification.count).to eq 7
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: item.name)
        expect(memo.user_id).to eq user4.id
        expect(memo.member_ids).to eq [admin.id]
        expect(memo.text).to eq ""
      end
    end
  end
end
