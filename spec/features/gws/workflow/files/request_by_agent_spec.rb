require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  context "request by agent" do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let(:form) { create(:gws_workflow_form, state: "public", agent_state: "enabled") }
    let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
    let(:file_name) { unique_id }

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

    let(:workflow_comment) { unique_id }
    let(:approve_comment1) { unique_id }
    let(:circulation_comment2) { unique_id }

    it do
      #
      # admin: 申請書の作成
      #
      login_gws_user
      visit new_gws_workflow_form_file_path(site: site, state: "all", form_id: form)

      within "form#item-form" do
        fill_in "item[name]", with: file_name
        fill_in "custom[#{column1.id}]", with: unique_id
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      #
      # admin: 代理で申請する（承認者 1 名＋回覧者 1 名）
      #
      visit gws_workflow_files_path(site: site, state: "all")
      click_on file_name

      within ".mod-workflow-request" do
        select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
        click_on I18n.t("workflow.buttons.select")

        choose "agent_type_agent"
        click_on I18n.t("gws/workflow.search_delegatees.index")
      end
      wait_for_cbox do
        expect(page).to have_content(user1.long_name)
        click_on user1.long_name
      end
      within ".mod-workflow-request" do
        click_on I18n.t("workflow.search_approvers.index")
      end
      wait_for_cbox do
        expect(page).to have_content(user2.long_name)
        click_on user2.long_name
      end
      within ".mod-workflow-request" do
        click_on I18n.t("workflow.search_circulations.index")
      end
      wait_for_cbox do
        expect(page).to have_content(user3.long_name)
        click_on user3.long_name
      end
      within ".mod-workflow-request" do
        fill_in "workflow[comment]", with: workflow_comment
        click_on I18n.t("workflow.buttons.request")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
      expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)

      expect(Gws::Workflow::File.count).to eq 1
      Gws::Workflow::File.all.first.tap do |item|
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to eq admin.id
        expect(item.workflow_state).to eq 'request'
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_circulations.count).to eq 1
        expect(item.workflow_circulations).to \
          include({level: 1, user_id: user3.id, state: 'pending', comment: ''})
      end

      expect(SS::Notification.count).to eq 1
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.request", name: file_name)
        expect(memo.user_id).to eq admin.id
        expect(memo.member_ids).to eq [user2.id]
        expect(memo.text).to eq ""
      end

      #
      # user2: 申請を承認する
      #
      login_user user2
      visit gws_workflow_files_path(site: site, state: "all")
      click_on file_name

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: approve_comment1
        click_on I18n.t("workflow.buttons.approve")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment1)}/)

      Gws::Workflow::File.all.first.tap do |item|
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to eq admin.id
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
        expect(item.workflow_circulations.count).to eq 1
        expect(item.workflow_circulations).to \
          include({level: 1, user_id: user3.id, state: 'unseen', comment: ''})
      end

      expect(SS::Notification.count).to eq 3
      SS::Notification.order_by(id: -1).second.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.approve", name: file_name)
        expect(memo.user_id).to eq user2.id
        expect(memo.member_ids).to include(admin.id, user1.id)
        expect(memo.text).to eq ""
      end
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.circular", name: file_name)
        expect(memo.user_id).to eq user2.id
        expect(memo.member_ids).to eq [user3.id]
        expect(memo.text).to eq ""
      end

      #
      # user3: 申請を確認する
      #
      login_user user3
      visit gws_workflow_files_path(site: site, state: "all")
      click_on file_name

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: circulation_comment2
        click_on I18n.t("workflow.links.set_seen")
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(circulation_comment2)}/)

      Gws::Workflow::File.all.first.tap do |item|
        expect(item.workflow_user_id).to eq user1.id
        expect(item.workflow_agent_id).to eq admin.id
        expect(item.workflow_state).to eq 'approve'
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment1, file_ids: nil})
        expect(item.workflow_circulations.count).to eq 1
        expect(item.workflow_circulations).to \
          include({level: 1, user_id: user3.id, state: 'seen', comment: circulation_comment2})
      end

      expect(SS::Notification.count).to eq 4
      SS::Notification.order_by(id: -1).first.tap do |memo|
        expect(memo.subject).to eq I18n.t("gws_notification.gws/workflow/file.comment", name: file_name)
        expect(memo.user_id).to eq user3.id
        expect(memo.member_ids).to include(admin.id, user1.id)
        expect(memo.text).to eq ""
      end
    end
  end
end
