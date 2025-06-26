require 'spec_helper'

describe Gws::Tabular::Gws::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'closed', workflow_state: 'disabled'
  end
  let!(:form_reference_column) do
    create(:gws_tabular_column_reference_field, cur_site: site, cur_form: form, order: 10, reference_form: form_referee)
  end

  let!(:form_referee) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'closed', workflow_state: 'disabled'
  end
  let!(:form_referee_column1) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form_referee, order: 10,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let!(:form_referee_column2) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form_referee, order: 20,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end
  let!(:form_referee_column3) do
    create(
      :gws_tabular_column_text_field, cur_site: site, cur_form: form_referee, order: 30,
      input_type: "single", validation_type: "none", i18n_state: "disabled")
  end

  context "with gws/tabular/column/lookup_field" do
    let(:name1) { "name-#{unique_id}" }
    let(:index_state1) { %w(none asc desc).sample }
    let(:index_state_label1) { I18n.t("gws/tabular.options.order_direction.#{index_state1}") }

    let(:name2) { "name-#{unique_id}" }
    let(:index_state2) { %w(none asc desc).sample }
    let(:index_state_label2) { I18n.t("gws/tabular.options.order_direction.#{index_state2}") }

    let(:name3) { "name-#{unique_id}" }
    let(:order3) { rand(10..20) }
    let(:tooltips3) { "tooltip-#{unique_id}" }
    let(:prefix_label3) { "pre-#{unique_id}"[0, 10] }
    let(:postfix_label3) { "pos-#{unique_id}"[0, 10] }
    let(:prefix_explanation3) { "<b>prefix-#{unique_id}</b>" }
    let(:postfix_explanation3) { "<b>postfix-#{unique_id}</b>" }
    let(:index_state3) { %w(none asc desc).sample }
    let(:index_state_label3) { I18n.t("gws/tabular.options.order_direction.#{index_state3}") }

    it do
      login_user admin, to: gws_tabular_gws_main_path(site: site)
      click_on space.i18n_name
      click_on form.i18n_name
      click_on I18n.t("gws/workflow.columns.index")
      wait_for_all_turbo_frames

      #
      # Create with default setting
      #
      within ".gws-column-list-toolbar[data-placement='top']" do
        wait_event_to_fire("gws:column:added") { click_on I18n.t("mongoid.models.gws/tabular/column/lookup_field") }
      end

      form.reload
      expect(form.columns.count).to eq 2

      #
      # Edit
      #
      within first(".gws-column-item") do
        # basic_info
        fill_in "item[name]", with: name1
        select form_reference_column.name, from: "item[reference_column_id]"
        select form_referee_column1.name, from: "item[lookup_column_id]"

        # オプション設定
        within ".gws-column-form-input-group[data-field-name='index_state']" do
          choose index_state_label1
        end

        wait_event_to_fire("turbo:frame-load") { click_on I18n.t("ss.buttons.save") }
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 2

      column = form.columns.second
      expect(column).to be_a(Gws::Tabular::Column::LookupField)
      expect(column.name).to eq name1
      expect(column.reference_column_id).to eq form_reference_column.id
      expect(column.lookup_column_id).to eq form_referee_column1.id
      expect(column.index_state).to eq index_state1

      #
      # Edit again
      #
      within first(".gws-column-item") do
        wait_event_to_fire("turbo:frame-load") { click_on "edit" }
      end
      within first(".gws-column-item") do
        # basic_info
        fill_in "item[name]", with: name2
        select form_referee_column2.name, from: "item[lookup_column_id]"
        # オプション設定
        within ".gws-column-form-input-group[data-field-name='index_state']" do
          choose index_state_label2
        end

        wait_event_to_fire("turbo:frame-load") { click_on I18n.t("ss.buttons.save") }
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 2

      column = form.columns.second
      expect(column).to be_a(Gws::Tabular::Column::LookupField)
      expect(column.name).to eq name2
      expect(column.reference_column_id).to eq form_reference_column.id
      expect(column.lookup_column_id).to eq form_referee_column2.id
      expect(column.index_state).to eq index_state2

      #
      # Edit in detail dialog
      #
      within first(".gws-column-item") do
        open_dialog "open_in_new"
      end
      within_dialog do
        within "form#item-form" do
          # basic_info
          fill_in "item[name]", with: name3
          fill_in "item[order]", with: order3
          fill_in "item[tooltips]", with: tooltips3
          fill_in "item[prefix_label]", with: prefix_label3
          fill_in "item[postfix_label]", with: postfix_label3
          fill_in "item[prefix_explanation]", with: prefix_explanation3
          fill_in "item[postfix_explanation]", with: postfix_explanation3
          # lookup_field
          select form_referee_column3.name, from: "item[lookup_column_id]"
          # tabular common
          select index_state_label3, from: "item[index_state]"

          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 2

      column = form.columns.second
      expect(column).to be_a(Gws::Tabular::Column::LookupField)
      # basic
      expect(column.name).to eq name3
      expect(column.order).to eq order3
      expect(column.tooltips.first).to eq tooltips3
      expect(column.prefix_label).to eq prefix_label3
      expect(column.postfix_label).to eq postfix_label3
      expect(column.prefix_explanation).to eq prefix_explanation3
      expect(column.postfix_explanation).to eq postfix_explanation3
      # lookup_field
      expect(column.reference_column_id).to eq form_reference_column.id
      expect(column.lookup_column_id).to eq form_referee_column3.id
      # tabular common
      expect(column.index_state).to eq index_state3
    end
  end
end
