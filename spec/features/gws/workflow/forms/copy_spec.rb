require 'spec_helper'

describe "gws_workflow_forms", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:dest_user) { create(:gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids) }
  let!(:form) do
    form = create(:gws_workflow_form, cur_site: site, state: "public")
    form.class.find(form.id)
  end
  let!(:column1) do
    column = create(:gws_column_text_field, cur_site: site, form: form, input_type: "text")
    column.class.find(column.id)
  end

  before { login_gws_user }

  context "copy" do
    it do
      visit gws_workflow_forms_path(site: site)
      click_on form.name
      within ".nav-menu" do
        click_on I18n.t("ss.links.copy")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.copy")
      end
      wait_for_notice I18n.t("ss.notice.copied")

      expect(Gws::Workflow::Form.all.count).to eq 2
      Gws::Workflow::Form.all.ne(id: form.id.to_s).first.tap do |copied_form|
        expect(copied_form.id.to_s).not_to eq form.id.to_s
        expect(copied_form.site_id).to eq form.site_id

        expect(copied_form.name).to eq "#{I18n.t("gws/notice.prefix.copy")}#{form.name}"
        expect(copied_form.order).to eq form.order
        expect(copied_form.state).to eq "closed"
        expect(copied_form.agent_state).to eq form.agent_state
        expect(copied_form.memo).to eq form.memo
        expect(copied_form.readable_setting_range).to eq form.readable_setting_range
        expect(copied_form.readable_custom_group_ids).to eq form.readable_custom_group_ids
        expect(copied_form.readable_group_ids).to eq form.readable_group_ids
        expect(copied_form.readable_member_ids).to eq form.readable_member_ids
        expect(copied_form.custom_group_ids).to eq form.custom_group_ids
        expect(copied_form.group_ids).to eq form.group_ids
        expect(copied_form.user_ids).to eq form.user_ids
        expect(copied_form.updated).to be >= form.updated
        expect(copied_form.created).to eq form.created

        copied_form.columns.to_a.tap do |copied_columns|
          expect(copied_columns.length).to eq 1
          copied_columns[0].tap do |copied_column|
            expect(copied_column.id.to_s).not_to eq column1.id.to_s
            expect(copied_column.class).to eq column1.class
            expect(copied_column.form_id.to_s).to eq copied_form.id.to_s
            expect(copied_column.name).to eq column1.name
            expect(copied_column.order).to eq column1.order
            expect(copied_column.required).to eq column1.required
            expect(copied_column.input_type).to eq column1.input_type
            expect(copied_column.tooltips).to eq column1.tooltips
            expect(copied_column.prefix_label).to eq column1.prefix_label
            expect(copied_column.postfix_label).to eq column1.postfix_label
            expect(copied_column.prefix_explanation).to eq column1.prefix_explanation
            expect(copied_column.postfix_explanation).to eq column1.postfix_explanation
            expect(copied_column.max_length).to eq column1.max_length
            expect(copied_column.place_holder).to eq column1.place_holder
            expect(copied_column.additional_attr).to eq column1.additional_attr
            expect(copied_column.updated).to be >= column1.updated
            expect(copied_column.created).to eq column1.created
          end
        end
      end

      form.reload
      expect(form.columns.count).to eq 1

      column1.reload
      expect(column1.form_id.to_s).to eq form.id.to_s
    end
  end
end
