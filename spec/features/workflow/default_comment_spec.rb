require 'spec_helper'

describe "default_comment", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:user) { cms_user }
  let!(:layout) { create_cms_layout }
  let!(:node) { create(:article_node_page, cur_site: site, layout_id: layout.id) }
  let!(:show_path) { article_page_path(site, node, item) }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context "with article/page" do
    context "when publish request" do
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'closed') }

      context "no setting" do
        it do
          login_cms_user
          visit show_path

          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user.long_name)
            find("tr[data-id='1,#{user.id}'] input[type=checkbox]").click
            wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
          end
          within ".mod-workflow-request" do
            expect(first('[name="workflow[comment]"]').value).to be_blank
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          item.reload
          expect(item.workflow_comment).to be_blank
        end
      end

      context "set default comment" do
        let!(:workflow_comment) { unique_id }

        before do
          site.workflow_default_comment = workflow_comment
          site.update!
        end

        it do
          login_cms_user
          visit show_path

          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user.long_name)
            find("tr[data-id='1,#{user.id}'] input[type=checkbox]").click
            wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
          end
          within ".mod-workflow-request" do
            expect(first('[name="workflow[comment]"]').value).to eq workflow_comment
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          item.reload
          expect(item.workflow_comment).to eq workflow_comment
        end
      end
    end

    context "when close request" do
      let!(:item) { create(:article_page, cur_site: site, cur_node: node, layout_id: layout.id, state: 'public') }

      context "no setting" do
        it do
          login_cms_user
          visit show_path

          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user.long_name)
            find("tr[data-id='1,#{user.id}'] input[type=checkbox]").click
            wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
          end
          within ".mod-workflow-request" do
            expect(first('[name="workflow[comment]"]').value).to be_blank
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          item.reload
          expect(item.workflow_comment).to be_blank
        end
      end

      context "set default comment" do
        let!(:workflow_comment) { unique_id }

        before do
          site.workflow_default_comment = workflow_comment
          site.update!
        end

        it do
          login_cms_user
          visit show_path

          within ".mod-workflow-request" do
            select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
            click_on I18n.t("workflow.buttons.select")
            wait_for_cbox_opened { click_on I18n.t("workflow.search_approvers.index") }
          end
          within_cbox do
            expect(page).to have_content(user.long_name)
            find("tr[data-id='1,#{user.id}'] input[type=checkbox]").click
            wait_for_cbox_closed { click_on I18n.t("workflow.search_approvers.select") }
          end
          within ".mod-workflow-request" do
            expect(first('[name="workflow[comment]"]').value).to be_blank
            click_on I18n.t("workflow.buttons.request")
          end
          expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))

          item.reload
          expect(item.workflow_comment).to be_blank
        end
      end
    end
  end
end
