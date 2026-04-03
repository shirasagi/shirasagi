require 'spec_helper'

describe Gws::Tabular::Gws::ColumnsController, type: :feature, dbscope: :example, js: true do
  let(:now) { Time.zone.now.change(sec: 0) }
  let!(:site) { gws_site }
  let!(:admin) { gws_user }

  let!(:space) { create :gws_tabular_space, cur_site: site, state: "public", readable_setting_range: "public" }
  let!(:form) do
    create :gws_tabular_form, cur_site: site, cur_space: space, state: 'closed', workflow_state: 'disabled'
  end

  context "with gws/tabular/column/text_field" do
    let(:name1) { "name-#{unique_id}" }
    let(:input_type1) { %w(single multi multi_html).sample }
    let(:input_type_label1) { I18n.t("gws/tabular.options.text_input_type.#{input_type1}") }
    let(:max_length1) { rand(100..200) }
    let(:i18n_default_value1) { i18n_translations(prefix: "default_value") }
    let(:required1) { %w(required optional).sample }
    let(:required_label1) { I18n.t("ss.options.state.#{required1}") }
    let(:unique_state1) { %w(disabled enabled).sample }
    let(:unique_state_label1) { I18n.t("ss.options.state.#{unique_state1}") }
    let(:validation_type1) { %w(none email tel url color).sample }
    let(:validation_type_label1) { I18n.t("gws/tabular.options.validation_type.#{validation_type1}") }
    let(:i18n_state1) { %w(disabled enabled).sample }
    let(:i18n_state_label1) { I18n.t("ss.options.state.#{i18n_state1}") }
    let(:index_state1) { %w(none asc desc).sample }
    let(:index_state_label1) { I18n.t("gws/tabular.options.order_direction.#{index_state1}") }

    let(:name2) { "name-#{unique_id}" }
    let(:input_type2) { %w(single multi multi_html).sample }
    let(:input_type_label2) { I18n.t("gws/tabular.options.text_input_type.#{input_type2}") }
    let(:max_length2) { rand(100..200) }
    let(:i18n_default_value2) { i18n_translations(prefix: "default_value") }
    let(:required2) { %w(required optional).sample }
    let(:required_label2) { I18n.t("ss.options.state.#{required2}") }
    let(:unique_state2) { %w(disabled enabled).sample }
    let(:unique_state_label2) { I18n.t("ss.options.state.#{unique_state2}") }
    let(:validation_type2) { %w(none email tel url color).sample }
    let(:validation_type_label2) { I18n.t("gws/tabular.options.validation_type.#{validation_type2}") }
    let(:i18n_state2) { %w(disabled enabled).sample }
    let(:i18n_state_label2) { I18n.t("ss.options.state.#{i18n_state2}") }
    let(:index_state2) { %w(none asc desc).sample }
    let(:index_state_label2) { I18n.t("gws/tabular.options.order_direction.#{index_state2}") }

    let(:name3) { "name-#{unique_id}" }
    let(:order3) { rand(10..20) }
    let(:required3) { %w(required optional).sample }
    let(:required_label3) { I18n.t("ss.options.state.#{required3}") }
    let(:tooltips3) { "tooltip-#{unique_id}" }
    let(:prefix_label3) { "pre-#{unique_id}"[0, 10] }
    let(:postfix_label3) { "pos-#{unique_id}"[0, 10] }
    let(:prefix_explanation3) { "<b>prefix-#{unique_id}</b>" }
    let(:postfix_explanation3) { "<b>postfix-#{unique_id}</b>" }
    let(:input_type3) { %w(single multi multi_html).sample }
    let(:input_type_label3) { I18n.t("gws/tabular.options.text_input_type.#{input_type3}") }
    let(:max_length3) { rand(100..200) }
    let(:i18n_default_value3) { i18n_translations(prefix: "default_value") }
    let(:validation_type3) { %w(none email tel url color).sample }
    let(:validation_type_label3) { I18n.t("gws/tabular.options.validation_type.#{validation_type3}") }
    let(:i18n_state3) { %w(disabled enabled).sample }
    let(:i18n_state_label3) { I18n.t("ss.options.state.#{i18n_state3}") }
    let(:index_state3) { %w(none asc desc).sample }
    let(:index_state_label3) { I18n.t("gws/tabular.options.order_direction.#{index_state3}") }
    let(:unique_state3) { %w(disabled enabled).sample }
    let(:unique_state_label3) { I18n.t("ss.options.state.#{unique_state3}") }

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
        wait_for_event_fired("gws:column:added") { click_on I18n.t("mongoid.models.gws/tabular/column/text_field") }
      end

      form.reload
      expect(form.columns.count).to eq 1

      #
      # Edit
      #
      within first(".gws-column-item") do
        # basic_info
        fill_in "item[name]", with: name1
        within ".gws-column-form-input-group[data-field-name='input_type']" do
          choose input_type_label1
        end
        fill_in "item[max_length]", with: max_length1
        I18n.available_locales.each do |lang|
          fill_in "item[i18n_default_value_translations][#{lang}]", with: i18n_default_value1[lang]
        end
        # option_setting
        within ".gws-column-form-input-group[data-field-name='required']" do
          choose required_label1
        end
        within ".gws-column-form-input-group[data-field-name='unique_state']" do
          choose unique_state_label1
        end
        if input_type1 == "single"
          within ".gws-column-form-input-group[data-field-name='validation_type']" do
            choose validation_type_label1
          end
          within ".gws-column-form-input-group[data-field-name='i18n_state']" do
            choose i18n_state_label1
          end
        end
        within ".gws-column-form-input-group[data-field-name='index_state']" do
          choose index_state_label1
        end

        wait_for_event_fired("turbo:frame-load") { click_on I18n.t("ss.buttons.save") }
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column).to be_a(Gws::Tabular::Column::TextField)
      expect(column.name).to eq name1
      expect(column.input_type).to eq input_type1
      expect(column.max_length).to eq max_length1
      I18n.available_locales.each do |lang|
        I18n.with_locale(lang) do
          expect(column.i18n_default_value).to eq i18n_default_value1[lang]
        end
      end
      expect(column.required).to eq required1
      expect(column.unique_state).to eq unique_state1
      if input_type1 == "single"
        expect(column.validation_type).to eq validation_type1
        expect(column.i18n_state).to eq i18n_state1
      else
        expect(column.validation_type).to eq "none"
        expect(column.i18n_state).to eq "disabled"
      end
      expect(column.index_state).to eq index_state1

      #
      # Edit again
      #
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") { click_on "edit" }
      end
      within first(".gws-column-item") do
        # basic_info
        fill_in "item[name]", with: name2
        within ".gws-column-form-input-group[data-field-name='input_type']" do
          choose input_type_label2
        end
        fill_in "item[max_length]", with: max_length2
        I18n.available_locales.each do |lang|
          fill_in "item[i18n_default_value_translations][#{lang}]", with: i18n_default_value2[lang]
        end
        # option_setting
        within ".gws-column-form-input-group[data-field-name='required']" do
          choose required_label2
        end
        within ".gws-column-form-input-group[data-field-name='unique_state']" do
          choose unique_state_label2
        end
        if input_type2 == "single"
          within ".gws-column-form-input-group[data-field-name='validation_type']" do
            choose validation_type_label2
          end
          within ".gws-column-form-input-group[data-field-name='i18n_state']" do
            choose i18n_state_label2
          end
        end
        within ".gws-column-form-input-group[data-field-name='index_state']" do
          choose index_state_label2
        end

        wait_for_event_fired("turbo:frame-load") { click_on I18n.t("ss.buttons.save") }
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column).to be_a(Gws::Tabular::Column::TextField)
      expect(column.name).to eq name2
      expect(column.input_type).to eq input_type2
      expect(column.max_length).to eq max_length2
      I18n.available_locales.each do |lang|
        I18n.with_locale(lang) do
          expect(column.i18n_default_value).to eq i18n_default_value2[lang]
        end
      end
      expect(column.required).to eq required2
      expect(column.unique_state).to eq unique_state2
      if input_type2 == "single"
        expect(column.validation_type).to eq validation_type2
        expect(column.i18n_state).to eq i18n_state2
      else
        expect(column.validation_type).to eq "none"
        expect(column.i18n_state).to eq "disabled"
      end
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
          select required_label3, from: "item[required]"
          fill_in "item[tooltips]", with: tooltips3
          fill_in "item[prefix_label]", with: prefix_label3
          fill_in "item[postfix_label]", with: postfix_label3
          fill_in "item[prefix_explanation]", with: prefix_explanation3
          fill_in "item[postfix_explanation]", with: postfix_explanation3
          # text_field
          select input_type_label3, from: "item[input_type]"
          fill_in "item[max_length]", with: max_length3
          I18n.available_locales.each do |lang|
            fill_in "item[i18n_default_value_translations][#{lang}]", with: i18n_default_value3[lang]
          end
          if input_type3 == "single"
            select validation_type_label3, from: "item[validation_type]"
            select i18n_state_label3, from: "item[i18n_state]"
          end
          # tabular common
          select index_state_label3, from: "item[index_state]"
          select unique_state_label3, from: "item[unique_state]"

          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column).to be_a(Gws::Tabular::Column::TextField)
      # basic
      expect(column.name).to eq name3
      expect(column.order).to eq order3
      expect(column.required).to eq required3
      expect(column.tooltips.first).to eq tooltips3
      expect(column.prefix_label).to eq prefix_label3
      expect(column.postfix_label).to eq postfix_label3
      expect(column.prefix_explanation).to eq prefix_explanation3
      expect(column.postfix_explanation).to eq postfix_explanation3
      # text_field
      expect(column.input_type).to eq input_type3
      expect(column.max_length).to eq max_length3
      I18n.available_locales.each do |lang|
        I18n.with_locale(lang) do
          expect(column.i18n_default_value).to eq i18n_default_value3[lang]
        end
      end
      if input_type3 == "single"
        expect(column.validation_type).to eq validation_type3
        expect(column.i18n_state).to eq i18n_state3
      else
        expect(column.validation_type).to eq "none"
        expect(column.i18n_state).to eq "disabled"
      end
      # tabular common
      expect(column.unique_state).to eq unique_state3
      expect(column.index_state).to eq index_state3
    end
  end
end
