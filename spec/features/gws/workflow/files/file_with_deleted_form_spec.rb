require 'spec_helper'

describe Gws::Workflow::FilesController, type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }
  let!(:dest_user) { create(:gws_user, group_ids: user.group_ids, gws_role_ids: user.gws_role_ids) }

  # 全部入りのフォーム
  let!(:form) { create(:gws_workflow_form, state: "public") }
  let!(:column1) { create(:gws_column_text_field, form: form, input_type: "text") }
  let!(:column2) { create(:gws_column_date_field, form: form) }
  let!(:column3) { create(:gws_column_number_field, form: form) }
  let(:column3_min) { column3.min_decimal.to_i }
  let(:column3_max) { column3.max_decimal.to_i }
  let(:column3_val) { (column3_min..column3_max).to_a.sample }
  let!(:column4) { create(:gws_column_url_field, form: form) }
  let!(:column5) { create(:gws_column_text_area, form: form) }
  let!(:column6) { create(:gws_column_select, form: form) }
  let!(:column7) { create(:gws_column_radio_button, form: form) }
  let!(:column8) { create(:gws_column_check_box, form: form) }
  let!(:column9) { create(:gws_column_file_upload, form: form) }
  let!(:column10) { create(:gws_column_section, form: form) }
  let!(:column11) { create(:gws_column_title, form: form) }

  let!(:item) do
    file = tmp_ss_file(contents: '0123456789', user: user)
    create(
      :gws_workflow_file, cur_user: user, form: form,
      column_values: [
        column1.serialize_value(unique_id),
        column2.serialize_value("2023/05/23"),
        column3.serialize_value(column3_val),
        column4.serialize_value("https://www.ss-proj.org/"),
        column5.serialize_value(Array.new(2) { unique_id }.join("\n")),
        column6.serialize_value(column6.select_options.sample),
        column7.serialize_value(column7.select_options.sample),
        column8.serialize_value([ column8.select_options.sample ]),
        column9.serialize_value([ file.id ]),
        column10.serialize_value(column10.default_value),
        column11.serialize_value(column11.default_value),
      ]
    )
  end

  before { login_user user }

  context "sort delete" do
    before { form.destroy }

    it do
      #
      # Soft Delete
      #
      visit gws_workflow_files_path(site: site, state: "all")
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.deleted).to be_present

      #
      # Hard Delete
      #
      visit gws_workflow_files_path(site: site, state: "all")
      within ".current-navi" do
        click_on I18n.t('ss.links.trash')
      end
      click_on item.name
      within ".nav-menu" do
        click_on I18n.t('ss.links.delete')
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      expect { item.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  context "sort delete all" do
    before { form.destroy }

    it do
      visit gws_workflow_files_path(site: site, state: "all")
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')

      item.reload
      expect(item.deleted).to be_present
    end
  end

  context "sort delete all with approved" do
    it do
      item.workflow_state = "approve"
      item.workflow_comment = "comment-#{unique_id}"
      item.save!

      visit gws_workflow_files_path(site: site, state: "all")
      wait_for_event_fired("ss:checked-all-list-items") { find('.list-head label.check input').set(true) }
      within ".list-head-action" do
        page.accept_confirm do
          click_on I18n.t("ss.links.delete")
        end
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      item.reload
      expect(item.deleted).to be_present
    end
  end
end
