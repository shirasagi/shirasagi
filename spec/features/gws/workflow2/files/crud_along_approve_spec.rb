require 'spec_helper'

describe "gws_workflow2_files", type: :feature, dbscope: :example, js: true do
  context "crud along with approve path" do
    let(:site) { gws_site }
    let(:user) { gws_user }
    let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: user.gws_role_ids }
    let!(:form) do
      create(
        :gws_workflow2_form_application, cur_site: site, state: "public",
        destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
      )
    end
    let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
    let(:index_path) { gws_workflow2_files_path(site, state: 'all') }
    let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
    let(:item_text) { unique_id }
    let(:item_text2) { unique_id }
    let(:now) { Time.zone.now.change(sec: 0) }

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
        within "#addon-gws-agents-addons-workflow2-custom_form" do
          fill_in "custom[#{column1.id}]", with: item_text
          wait_for_cbox_opened { click_on I18n.t("ss.buttons.upload") }
        end
      end
      within_cbox do
        within "article.file-view" do
          wait_for_cbox_closed { click_on file.name }
        end
      end
      within "form#item-form" do
        expect(page).to have_content(file.name)
        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".mod-workflow-request" do
        expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
      end

      expect(Gws::Workflow2::File.site(site).count).to eq 1
      item = Gws::Workflow2::File.site(site).first
      form_name = [ form.name, now.strftime("%Y%m%d"), form.current_style_sequence ].join("_")
      expect(item.name).to eq form_name
      expect(item.column_values.count).to eq 2
      item.column_values.to_a.tap do |column_values|
        column_values.find { |column_value| column_value.is_a?(Gws::Column::Value::TextField) }.tap do |column_value|
          expect(column_value.value).to eq item_text
        end
        column_values.find { |column_value| column_value.is_a?(Gws::Column::Value::FileUpload) }.tap do |column_value|
          expect(column_value.files.count).to eq 1
          expect(column_value.files.first.id).to eq file.id
          column_value.files.first.tap do |column_file|
            expect(column_file.id).to eq file.id
            expect(column_file.site_id).to be_blank
            expect(column_file.model).to eq "Gws::Workflow2::File"
            expect(column_file.owner_item_id).to eq item.id
            expect(column_file.owner_item_type).to eq item.class.name
          end
        end
      end
      expect(item.group_ids).to be_blank
      expect(item.user_ids).to include(gws_user.id)
      expect(item.custom_group_ids).to be_blank
      expect(item.destination_group_ids).to eq [ dest_group.id ]
      expect(item.destination_user_ids).to eq [ dest_user.id ]
      expect(item.destination_treat_state).to eq "untreated"

      #
      # Update
      #
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-custom_form" do
          fill_in "custom[#{column1.id}]", with: item_text2
        end
        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.saved')

      within ".mod-workflow-request" do
        expect(page).to have_css(".workflow_approvers", text: I18n.t("gws/workflow2.errors.messages.superior_is_not_found"))
      end

      expect(Gws::Workflow2::File.site(site).count).to eq 1
      item = Gws::Workflow2::File.site(site).first
      expect(item.column_values.count).to eq 2
      item.column_values.to_a.tap do |column_values|
        column_values.find { |column_value| column_value.is_a?(Gws::Column::Value::TextField) }.tap do |column_value|
          expect(column_value.value).to eq item_text2
        end
        column_values.find { |column_value| column_value.is_a?(Gws::Column::Value::FileUpload) }.tap do |column_value|
          expect(column_value.files.count).to eq 1
          column_value.files.first.tap do |column_file|
            expect(column_file.id).to eq file.id
            expect(column_file.site_id).to be_blank
            expect(column_file.model).to eq "Gws::Workflow2::File"
            expect(column_file.owner_item_id).to eq item.id
            expect(column_file.owner_item_type).to eq item.class.name
          end
        end
      end

      #
      # Soft Delete
      #
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Workflow2::File.site(site).count).to eq 1
      Gws::Workflow2::File.site(site).first.tap do |workflow|
        expect(workflow.deleted).not_to be_nil
      end
    end
  end
end
