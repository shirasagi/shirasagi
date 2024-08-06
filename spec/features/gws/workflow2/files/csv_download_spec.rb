require 'spec_helper'

describe Gws::Workflow2::FilesController, type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:admin) { gws_user }
  let(:form) { create(:gws_workflow2_form_application, state: "public", agent_state: "enabled") }
  let!(:column1) { create(:gws_column_text_field, cur_site: site, cur_form: form, input_type: "text") }
  let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form) }

  let(:column1_value) { unique_id }
  let(:file1) { tmp_ss_file(contents: '0123456789', user: admin) }
  let(:file2) { tmp_ss_file(contents: '0123456789', user: admin) }

  let!(:item2) do
    Gws::Workflow2::File.create!(
      cur_site: site, cur_user: admin, name: "name-#{unique_id}", cur_form: form,
      column_values: [ column1.serialize_value(column1_value), column2.serialize_value([ file2.id ]) ],
      destination_treat_state: "untreated"
    )
  end

  before do
    login_gws_user
  end

  context "csv download" do
    context "custom form file download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on item2.name
        wait_for_js_ready
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_comment")
        end

        wait_for_download

        I18n.with_locale(I18n.default_locale) do
          csv = ::CSV.read(downloads.first, headers: true)
          expect(csv.length).to eq 1
          expect(csv[0][Gws::Workflow2::File.t(:name)]).to eq item2.name
          expect(csv[0]["#{form.name}/#{column1.name}"]).to eq column1_value
          expect(csv[0]["#{form.name}/#{column2.name}"]).to eq file2.name
        end

        # wait workflow route shown to avoid causing exceptions
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
      end
    end
  end

  context "attachments download" do
    context "custom form file download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        click_on item2.name
        wait_for_js_ready
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
        accept_confirm(I18n.t("ss.confirm.download")) do
          click_on I18n.t("gws/workflow.links.download_attachment")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file2.download_filename)

        # wait workflow route shown to avoid causing exceptions
        within ".mod-workflow-request" do
          expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
        end
      end
    end

    context "all files download" do
      it do
        visit gws_workflow2_files_path(site: site, state: "all")
        wait_event_to_fire("ss:checked-all-list-items") { find(".gws-workflow .list-head input[type=checkbox]").click }

        accept_confirm do
          click_on I18n.t("gws/survey.buttons.zip_all_files")
        end

        wait_for_download

        entry_names = ::Zip::File.open(downloads.first) do |entries|
          entries.map { |entry| entry.name }
        end
        expect(entry_names).to include(file1.download_filename, file2.download_filename)
      end
    end
  end
end
