require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  context "workflow_my_group" do
    let(:site) { gws_site }
    let!(:item) { create :gws_workflow_file, cur_site: site }

    before do
      site.workflow_my_group = workflow_my_group
      site.save!

      login_gws_user
    end

    context "with 'enabled'" do
      let(:workflow_my_group) { "enabled" }

      it do
        visit gws_workflow_file_path(site: site, id: item, state: 'all')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "with 'disabled'" do
      let(:workflow_my_group) { "disabled" }

      it do
        visit gws_workflow_file_path(site: site, id: item, state: 'all')
        expect(page).to have_css("#addon-workflow-agents-addons-approver", text: I18n.t("workflow.empty_route_options"))
      end
    end
  end

  context "SS.config.workflow.disable_my_group" do
    before do
      @save_config = SS.config.workflow.disable_my_group
      SS.config.replace_value_at(:workflow, 'disable_my_group', disable_my_group)

      login_gws_user
    end

    context "with false" do
      let(:site) { gws_site }
      let!(:item) { create :gws_workflow_file, cur_site: site }
      let(:disable_my_group) { false }

      it do
        visit gws_workflow_file_path(site: site, id: item, state: 'all')
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
      end
    end

    context "with 'disabled'" do
      let(:site) { gws_site }
      let!(:item) { create :gws_workflow_file, cur_site: site }
      let(:disable_my_group) { true }

      it do
        visit gws_workflow_file_path(site: site, id: item, state: 'all')
        expect(page).to have_css("#addon-workflow-agents-addons-approver", text: I18n.t("workflow.empty_route_options"))
      end
    end
  end
end
