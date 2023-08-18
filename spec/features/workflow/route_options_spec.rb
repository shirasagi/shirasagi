require 'spec_helper'

describe "route options", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:article_node_page) }
  let(:item) { create(:article_page, cur_node: node, state: 'closed') }
  let(:show_path) { article_page_path(site, node, item) }

  context "enable workflow_my_group" do
    before { login_cms_user }

    context "no workflow route" do
      it do
        visit show_path
        within ".mod-workflow-request" do
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        end
      end
    end

    context "workflow route given" do
      let!(:workflow_route) { create :workflow_route }

      it do
        visit show_path
        within ".mod-workflow-request" do
          expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(page).to have_css("#workflow_route", text: workflow_route.name)
        end
      end
    end
  end

  context "disable workflow_my_group" do
    before do
      site.workflow_my_group = "disabled"
      site.update!
      login_cms_user
    end

    context "no workflow route" do
      it do
        visit show_path
        within ".mod-workflow-request" do
          expect(page).to have_no_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(page).to have_text(I18n.t("workflow.empty_route_options"))
        end
      end
    end

    context "workflow route given" do
      let!(:workflow_route) { create :workflow_route }

      it do
        visit show_path
        within ".mod-workflow-request" do
          expect(page).to have_no_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
          expect(page).to have_css("#workflow_route", text: workflow_route.name)
        end
      end
    end
  end
end
