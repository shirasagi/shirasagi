require 'spec_helper'

describe "gws_workflow2_files", type: :feature, dbscope: :example, js: true do
  context "crud soft delete" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let!(:form) { create(:gws_workflow2_form_application, cur_site: site, state: "public") }
    let!(:column1) do
      create(:gws_column_text_field, cur_site: site, form: form, input_type: "text", required: "optional")
    end
    let(:index_path) { gws_workflow2_files_path(site, state: 'all') }
    let(:item_text) { unique_id }

    before { login_gws_user }

    it do
      visit index_path
      click_on I18n.t('gws/workflow2.navi.approve')

      #
      # Create
      #
      within ".nav-menu" do
        click_link I18n.t('gws/workflow2.navi.find_by_keyword')
      end
      within ".gws-workflow-select-forms-table" do
        click_on form.name
      end
      within "form#item-form" do
        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      #
      # Prepare
      #
      column1.required = 'required'
      column1.save

      #
      # Soft Delete
      #
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end

      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))
      expect(Gws::Workflow2::File.site(site).count).to eq 1
      Gws::Workflow2::File.site(site).first.tap do |workflow|
        expect(workflow.deleted).not_to be_nil
      end
    end
  end
end
