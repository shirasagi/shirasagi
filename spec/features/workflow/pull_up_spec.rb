require 'spec_helper'

describe "pull_up", dbscope: :example, js: true do
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
  let(:remand_comment3) { unique_id }

  let!(:route) do
    create(
      :workflow_route, name: route_name, pull_up: 'enabled',
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

    context "last user pulls up a request. this is most usual case" do
      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user3: pull up request, he is the last one
        #
        login_user user3
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.pull_up")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers[0]).to \
          eq({level: 1, user_id: user1.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[1]).to \
          eq({level: 2, user_id: user2.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[2]).to \
          eq({level: 3, user_id: user3.id, editable: '', state: 'approve', comment: approve_comment3})

        expect(Sys::MailLog.count).to eq 4
      end
    end

    context "intermediate user pulls up a request" do
      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user2: pull up request
        #
        login_user user2
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.pull_up")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          eq({level: 1, user_id: user1.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[1]).to \
          eq({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[2]).to \
          eq({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 4
      end
    end
  end

  context "with cms/page at root" do
    let!(:item) { create(:cms_page, cur_site: site, layout_id: layout.id, state: 'closed') }
    let(:show_path) { cms_page_path(site, item) }

    context "last user pulls up a request. this is most usual case" do
      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user3: pull up request, he is the last one
        #
        login_user user3
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment3
          click_on I18n.t("workflow.buttons.pull_up")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment3)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers[0]).to \
          eq({level: 1, user_id: user1.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[1]).to \
          eq({level: 2, user_id: user2.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[2]).to \
          eq({level: 3, user_id: user3.id, editable: '', state: 'approve', comment: approve_comment3})

        expect(Sys::MailLog.count).to eq 4
      end
    end

    context "intermediate user pulls up a request" do
      it do
        login_cms_user
        visit show_path

        #
        # admin: send request
        #
        within ".mod-workflow-request" do
          select route_name, from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 3
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        expect(Sys::MailLog.count).to eq 3

        #
        # user2: pull up request
        #
        login_user user2
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.pull_up")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to \
          eq({level: 1, user_id: user1.id, editable: '', state: 'other_pulled_up', comment: ''})
        expect(item.workflow_approvers[1]).to \
          eq({level: 2, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2})
        expect(item.workflow_approvers[2]).to \
          eq({level: 3, user_id: user3.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 4
      end
    end
  end
end
