require 'spec_helper'

describe "gws_board_topics", type: :feature, dbscope: :example, tmpdir: true do
  context "approve file", js: true do
    let(:site) { gws_site }
    let(:admin) { gws_user }
    let(:sys) { Gws::User.find_by uid: 'sys' }
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
    let(:item) { create :gws_workflow_file }
    let(:show_path) { gws_workflow_file_path site, item }
    let(:workflow_comment) { unique_id }
    let(:remand_comment1) { unique_id }
    let(:remand_comment2) { unique_id }

    it do
      login_gws_user
      visit show_path

      #
      # admin: 申請する
      #
      within ".mod-workflow-request" do
        click_on "選択"

        within ".ms-container" do
          find("li.ms-elem-selectable", text: /#{Regexp.escape(user1.uid)}/).click
          find("li.ms-elem-selectable", text: /#{Regexp.escape(user2.uid)}/).click
        end

        fill_in "workflow[comment]", with: workflow_comment
        click_on "申請"
      end
      expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(user1.uid)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, state: 'request', comment: ''})
      expect(item.workflow_approvers[1]).to eq({level: 1, user_id: user2.id, state: 'request', comment: ''})

      #
      # user1: 申請を承認する
      #
      login_user user1
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment1
        click_on "承認"
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(remand_comment1)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'request'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, state: 'approve', comment: remand_comment1})
      expect(item.workflow_approvers[1]).to eq({level: 1, user_id: user2.id, state: 'request', comment: ''})

      #
      # user2: 申請を承認する
      #
      login_user user2
      visit show_path

      within ".mod-workflow-approve" do
        fill_in "remand[comment]", with: remand_comment2
        click_on "承認"
      end

      expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(remand_comment2)}/)

      item.reload
      expect(item.workflow_user_id).to eq admin.id
      expect(item.workflow_state).to eq 'approve'
      expect(item.workflow_comment).to eq workflow_comment
      expect(item.workflow_approvers.count).to eq 2
      expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, state: 'approve', comment: remand_comment1})
      expect(item.workflow_approvers[1]).to eq({level: 1, user_id: user2.id, state: 'approve', comment: remand_comment2})
    end
  end
end
