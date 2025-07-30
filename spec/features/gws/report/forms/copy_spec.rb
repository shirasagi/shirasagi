require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column1_text1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "optional", input_type: "text")
  end

  before { login_gws_user }

  context "copy" do
    it do
      visit gws_report_forms_path(site: site)
      click_on form.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.copy")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.copy")
      end
      wait_for_notice I18n.t("ss.notice.copied")

      expect(Gws::Report::Form.all.count).to eq 2
      Gws::Report::Form.all.ne(id: form.id.to_s).first.tap do |copied_form|
        expect(copied_form.id.to_s).not_to eq form.id.to_s
        expect(copied_form.site_id).to eq form.site_id

        expect(copied_form.name).to eq "#{I18n.t("gws/notice.prefix.copy")} #{form.name}"
        expect(copied_form.order).to eq form.order
        expect(copied_form.state).to eq "closed"
        expect(copied_form.memo).to eq form.memo
        expect(copied_form.category_ids).to eq form.category_ids
        expect(copied_form.readable_setting_range).to eq form.readable_setting_range
        expect(copied_form.readable_custom_group_ids).to eq form.readable_custom_group_ids
        expect(copied_form.readable_group_ids).to eq form.readable_group_ids
        expect(copied_form.readable_member_ids).to eq form.readable_member_ids
        expect(copied_form.custom_group_ids).to eq form.custom_group_ids
        expect(copied_form.group_ids).to eq form.group_ids
        expect(copied_form.user_ids).to eq form.user_ids

        copied_form.columns.to_a.tap do |copied_columns|
          expect(copied_columns.length).to eq 1
          copied_columns[0].tap do |copied_column|
            expect(copied_column.id.to_s).not_to eq column1_text1.id.to_s
            expect(copied_column.class).to eq column1_text1.class
            expect(copied_column.form_id.to_s).to eq copied_form.id.to_s
            expect(copied_column.name).to eq column1_text1.name
            expect(copied_column.order).to eq column1_text1.order
            expect(copied_column.required).to eq column1_text1.required
            expect(copied_column.input_type).to eq column1_text1.input_type
            expect(copied_column.tooltips).to eq column1_text1.tooltips
            expect(copied_column.prefix_label).to eq column1_text1.prefix_label
            expect(copied_column.postfix_label).to eq column1_text1.postfix_label
            expect(copied_column.prefix_explanation).to eq column1_text1.prefix_explanation
            expect(copied_column.postfix_explanation).to eq column1_text1.postfix_explanation
            expect(copied_column.max_length).to eq column1_text1.max_length
            expect(copied_column.place_holder).to eq column1_text1.place_holder
            expect(copied_column.additional_attr).to eq column1_text1.additional_attr
          end
        end
      end

      form.reload
      expect(form.columns.count).to eq 1

      column1_text1.reload
      expect(column1_text1.form_id.to_s).to eq form.id.to_s
    end
  end
end
