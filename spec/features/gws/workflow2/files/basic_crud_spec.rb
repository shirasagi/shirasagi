require 'spec_helper'

describe "gws_workflow2_files", type: :feature, dbscope: :example, js: true do
  context "basic crud with minimum permissions" do
    let!(:site) { gws_site }
    let!(:admin) { gws_user }
    let!(:minimum_role) { create(:gws_role, cur_site: site, permissions: %w(use_gws_workflow2)) }
    let!(:user) { create(:gws_user, :gws_workflow_notice, group_ids: admin.group_ids, gws_role_ids: [minimum_role.id]) }
    let!(:dest_group) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:dest_user) { create :gws_user, group_ids: [ dest_group.id ], gws_role_ids: [minimum_role.id] }
    let!(:form) do
      create(
        :gws_workflow2_form_application, cur_site: site, state: "public",
        destination_group_ids: [ dest_group.id ], destination_user_ids: [ dest_user.id ]
      )
    end
    let!(:column1) { create(:gws_column_text_field, cur_site: site, form: form, input_type: "text") }
    let!(:column2) { create(:gws_column_file_upload, cur_site: site, cur_form: form, upload_file_count: 1) }
    let!(:file) { tmp_ss_file(contents: '0123456789', user: user) }
    let(:item_text) { unique_id }
    let(:item_text2) { unique_id }
    let(:now) { Time.zone.now.change(sec: 0) }

    before { login_user user }

    it do
      #
      # Create
      #
      visit gws_workflow2_files_main_path(site: site)
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
      wait_for_turbo_frame "#workflow-approver-frame"

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
      expect(item.destination_group_ids).to eq [ dest_group.id ]
      expect(item.destination_user_ids).to eq [ dest_user.id ]
      expect(item.destination_treat_state).to eq "untreated"

      #
      # Update
      #
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
      click_on I18n.t("ss.links.edit")
      within "form#item-form" do
        within "#addon-gws-agents-addons-workflow2-custom_form" do
          fill_in "custom[#{column1.id}]", with: item_text2
        end
        click_on I18n.t("gws/workflow2.buttons.save_and_apply")
      end
      wait_for_notice I18n.t('ss.notice.saved')
      wait_for_turbo_frame "#workflow-approver-frame"

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
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
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

      #
      # Undo Delete
      #
      visit gws_workflow2_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t("ss.navi.trash")
      end
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.restore")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.restore")
      end
      wait_for_notice I18n.t('ss.notice.restored')

      expect(Gws::Workflow2::File.site(site).count).to eq 1
      Gws::Workflow2::File.site(site).first.tap do |workflow|
        expect(workflow.deleted).to be_nil
      end

      #
      # Hard Delete
      #
      visit gws_workflow2_files_main_path(site: site)
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      visit gws_workflow2_files_main_path(site: site)
      within ".current-navi" do
        click_on I18n.t("ss.navi.trash")
      end
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect(Gws::Workflow2::File.site(site).count).to eq 0
    end
  end
end
