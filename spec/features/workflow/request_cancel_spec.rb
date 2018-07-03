require 'spec_helper'

describe "request cancel", dbscope: :example, js: true do
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
      :workflow_route, name: route_name,
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

    context "cancel request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

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

        expect(Sys::MailLog.count).to eq 1

        #
        # admin: cancel request
        #
        login_cms_user
        visit show_path

        page.accept_confirm do
          within ".mod-workflow-view" do
            click_on I18n.t("workflow.buttons.cancel")
          end
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(I18n.t("workflow.state.cancelled"))}/)

        item.reload
        expect(item.workflow_state).to eq "cancelled"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        # no mails are sent
        expect(Sys::MailLog.count).to eq 1
      end
    end
  end

  context "with cms/page at root" do
    let!(:item) { create(:cms_page, cur_site: site, layout_id: layout.id, state: 'closed') }
    let(:show_path) { cms_page_path(site, item) }

    context "cancel request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

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

        expect(Sys::MailLog.count).to eq 1

        #
        # admin: cancel request
        #
        login_cms_user
        visit show_path

        page.accept_confirm do
          within ".mod-workflow-view" do
            click_on I18n.t("workflow.buttons.cancel")
          end
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(I18n.t("workflow.state.cancelled"))}/)

        item.reload
        expect(item.workflow_state).to eq "cancelled"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers[0]).to eq({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers[1]).to eq({level: 2, user_id: user2.id, editable: '', state: 'pending', comment: ''})
        expect(item.workflow_approvers[2]).to eq({level: 3, user_id: user3.id, editable: '', state: 'pending', comment: ''})

        # no mails are sent
        expect(Sys::MailLog.count).to eq 1
      end
    end
  end
end
