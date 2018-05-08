require 'spec_helper'

describe "my_group", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:group) { cms_group }
  let(:layout) { create_cms_layout }
  let(:role_ids) { cms_user.cms_role_ids }
  let(:group_ids) { cms_user.group_ids }
  let!(:user1) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let!(:user2) { create(:cms_test_user, group_ids: group_ids, cms_role_ids: role_ids) }
  let(:workflow_comment) { unique_id }
  let(:approve_comment1) { unique_id }
  let(:approve_comment2) { unique_id }
  let(:remand_comment1) { unique_id }
  let(:remand_comment2) { unique_id }

  context "with article/page" do
    let(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
    let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }
    let(:show_path) { article_page_path(site, node, item) }

    context "when all users approve request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          within ".ms-container" do
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user1.uid)}/).click
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user2.uid)}/).click
          end

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user1: approve request
        #
        login_user user1
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: approve request
        #
        login_user user2
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment2
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(approve_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "approve"
        expect(item.state).to eq "public"
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'approve', comment: approve_comment2})

        expect(Sys::MailLog.count).to eq 3
      end
    end

    context "when first user remands request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          within ".ms-container" do
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user1.uid)}/).click
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user2.uid)}/).click
          end

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user1: remand request
        #
        login_user user1
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment1
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(remand_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'remand', comment: remand_comment1})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 3
      end
    end

    context "when first user approves request and then second user remands request" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          within ".ms-container" do
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user1.uid)}/).click
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user2.uid)}/).click
          end

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user1: approve request
        #
        login_user user1
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment1
          click_on I18n.t("workflow.buttons.approve")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(approve_comment1)}/)

        item.reload
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

        #
        # user2: remand request
        #
        login_user user2
        visit show_path

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: remand_comment2
          click_on I18n.t("workflow.buttons.remand")
        end

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(remand_comment2)}/)

        item.reload
        expect(item.workflow_state).to eq "remand"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user1.id, editable: '', state: 'approve', comment: approve_comment1})
        expect(item.workflow_approvers).to \
          include({level: 1, user_id: user2.id, editable: '', state: 'remand', comment: remand_comment2})

        expect(Sys::MailLog.count).to eq 3
      end
    end

    context "when request is cancelled" do
      it do
        #
        # admin: send request
        #
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")

          within ".ms-container" do
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user1.uid)}/).click
            find("li.ms-elem-selectable", text: /#{Regexp.escape(user2.uid)}/).click
          end

          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(user1.uid)}/)

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 2
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2

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

        expect(page).to have_css(".mod-workflow-view dd", text: /#{Regexp.escape(I18n.t("workflow.state.cancelled"))}/)

        item.reload
        expect(item.workflow_state).to eq "cancelled"
        expect(item.state).to eq "closed"
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        expect(item.workflow_approvers).to include({level: 1, user_id: user2.id, editable: '', state: 'request', comment: ''})

        expect(Sys::MailLog.count).to eq 2
      end
    end
  end
end
