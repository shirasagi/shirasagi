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
        login_cms_user
        visit show_path

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open do
            click_on I18n.t("workflow.search_approvers.index")
          end
        end
        wait_for_cbox do
          expect(page).to have_content(user1.long_name)
          find("tr[data-id='1,#{user1.id}'] input[type=checkbox]").click
          wait_cbox_close do
            click_on I18n.t("workflow.search_approvers.select")
          end
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        # no backups are created while requesting approve
        expect(item.backups.count).to eq 1

        #
        # user1: edit requested page
        #
        login_user user1
        visit show_path
        click_on I18n.t("ss.links.edit")
        within "#item-form" do
          fill_in_ckeditor "item[html]", with: unique_id
          click_on I18n.t("ss.buttons.draft_save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

        item.reload
        expect(item.workflow_user_id).to eq cms_user.id
        expect(item.workflow_state).to eq "request"
        expect(item.state).to eq "closed"
        expect(item.workflow_comment).to eq workflow_comment
        expect(item.workflow_approvers.count).to eq 1
        expect(item.workflow_approvers).to include({level: 1, user_id: user1.id, editable: '', state: 'request', comment: ''})
        # no backups are created while requesting approve
        expect(item.backups.count).to eq 2
      end
    end
  end
end
