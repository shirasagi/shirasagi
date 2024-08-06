require 'spec_helper'

describe "gws_daily_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
  let!(:form) { create :gws_daily_report_form, cur_site: site, daily_report_group: group1 }
  let!(:column_type) { I18n.with_locale(gws_user.lang) { I18n.t("gws.columns").stringify_keys.to_a.sample } }
  # let!(:column_type) { I18n.with_locale(gws_user.lang) { [ "gws/title", I18n.t("gws.columns.gws/title") ] } }
  # let!(:column_type) { I18n.with_locale(gws_user.lang) { [ "gws/section", I18n.t("gws.columns.gws/section") ] } }
  # let!(:column_type) { I18n.with_locale(gws_user.lang) { [ "gws/radio_button", I18n.t("gws.columns.gws/radio_button") ] } }
  let(:available_fields_map) do
    common = %i(name order required tooltips label explanation)
    {
      "gws/title" => %i(title order title_explanation),
      "gws/text_field" => common + %i(text_input_type max_length place_holder additional_attr),
      "gws/date_field" => common + %i(date_input_type place_holder),
      "gws/number_field" => common + %i(decimal max_length place_holder additional_attr),
      "gws/url_field" => common + %i(max_length place_holder additional_attr),
      "gws/text_area" => common + %i(max_length place_holder additional_attr),
      "gws/select" => common + %i(place_holder select_options),
      "gws/radio_button" => common + %i(select_options other_option),
      "gws/check_box" => common + %i(select_options),
      "gws/file_upload" => common + %i(upload_file_count),
      "gws/section" => %i(name),
    }
  end
  let(:available_fields) { available_fields_map[column_type[0]] }

  before { login_gws_user }

  context "column selected randomly crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:title) { unique_id }
    let(:title2) { unique_id }
    let(:order) { rand(10) }
    let(:required) { %w(required optional).sample }
    let(:required_label) { I18n.t("ss.options.state.#{required}") }
    let(:tooltips) { Array.new(rand(3..5)) { unique_id } }
    let(:prefix_label) { unique_id[0, 10] }
    let(:postfix_label) { unique_id[0, 10] }
    let(:prefix_explanation) { unique_id[0, 10] }
    let(:postfix_explanation) { unique_id[0, 10] }
    let(:title_explanation) { Array.new(rand(3..5)) { unique_id } }
    let(:text_input_type) { %w(text email tel).sample }
    let(:text_input_type_label) { I18n.t("gws/column.options.column_input_type.#{text_input_type}") }
    let(:date_input_type) { %w(date datetime).sample }
    let(:date_input_type_label) { I18n.t("gws/column.options.date_input_type.#{date_input_type}") }
    let(:min_decimal) { rand(10) }
    let(:max_decimal) { min_decimal + rand(10) }
    let(:initial_decimal) { (min_decimal + max_decimal) / 2 }
    let(:scale) { rand(10) }
    let(:minus_type) { %w(normal filled_triangle triangle).sample }
    let(:minus_type_label) { I18n.t("gws/column.options.minus_type.#{minus_type}") }
    let(:max_length) { rand(10) }
    let(:place_holder) { unique_id }
    let(:additional_attr) { unique_id }
    let(:upload_file_count) { rand(1..5) }
    let(:upload_file_count_label) { upload_file_count.to_s }
    let(:select_options) { Array.new(rand(3..5)) { unique_id } }
    let(:other_state) { %w(enabled disabled).sample }
    let(:other_state_label) { I18n.t("ss.options.state.#{other_state}") }
    let(:other_required) { %w(required optional).sample }
    let(:other_required_label) { I18n.t("ss.options.state.#{other_required}") }

    it do
      #
      # Create
      #
      visit gws_daily_report_forms_path(site: site)
      click_on form.name
      click_on I18n.t('gws/daily_report.columns.index')

      within ".gws-column-list-toolbar[data-placement='top'] [data-module='gws']" do
        wait_for_event_fired("gws:column:added") { click_on column_type[1] }
      end
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") { click_on "cancel" }
      end
      clear_notice
      within first(".gws-column-item") do
        open_dialog "open_in_new"
      end
      within_dialog do
        within "form#item-form" do
          if available_fields.include?(:name)
            fill_in "item[name]", with: name
          end
          if available_fields.include?(:title)
            fill_in "item[title]", with: title
          end
          if available_fields.include?(:order)
            fill_in "item[order]", with: order
          end
          if available_fields.include?(:required)
            select required_label, from: "item[required]"
          end
          if available_fields.include?(:tooltips)
            fill_in "item[tooltips]", with: tooltips.join("\n")
          end
          if available_fields.include?(:label)
            fill_in "item[prefix_label]", with: prefix_label
            fill_in "item[postfix_label]", with: postfix_label
          end
          if available_fields.include?(:explanation)
            fill_in "item[prefix_explanation]", with: prefix_explanation
            fill_in "item[postfix_explanation]", with: postfix_explanation
          end
          if available_fields.include?(:title_explanation)
            fill_in "item[explanation]", with: title_explanation.join("\n")
          end
          if available_fields.include?(:text_input_type)
            select text_input_type_label, from: "item[input_type]"
          end
          if available_fields.include?(:date_input_type)
            select date_input_type_label, from: "item[input_type]"
          end
          if available_fields.include?(:decimal)
            fill_in "item[min_decimal]", with: min_decimal
            fill_in "item[max_decimal]", with: max_decimal
            fill_in "item[initial_decimal]", with: initial_decimal
            fill_in "item[scale]", with: scale
            select minus_type_label, from: "item[minus_type]"
          end
          if available_fields.include?(:max_length)
            fill_in "item[max_length]", with: max_length
          end
          if available_fields.include?(:place_holder)
            fill_in "item[place_holder]", with: place_holder
          end
          if available_fields.include?(:additional_attr)
            fill_in "item[additional_attr]", with: additional_attr
          end
          if available_fields.include?(:upload_file_count)
            select upload_file_count_label, from: "item[upload_file_count]"
          end
          if available_fields.include?(:select_options)
            fill_in "item[select_options]", with: select_options.join("\n")
          end
          if available_fields.include?(:other_option)
            select other_state_label, from: "item[other_state]"
            select other_required_label, from: "item[other_required]"
          end

          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      if available_fields.include?(:name)
        expect(column.name).to eq name
      end
      if available_fields.include?(:title)
        expect(column.title).to eq title
      end
      if available_fields.include?(:order)
        expect(column.order).to eq order
      end
      if available_fields.include?(:required)
        expect(column.required).to eq required
      end
      if available_fields.include?(:tooltips)
        expect(column.tooltips).to eq tooltips
      end
      if available_fields.include?(:label)
        expect(column.prefix_label).to eq prefix_label
        expect(column.postfix_label).to eq postfix_label
      end
      if available_fields.include?(:explanation)
        expect(column.prefix_explanation).to eq prefix_explanation
        expect(column.postfix_explanation).to eq postfix_explanation
      end
      if available_fields.include?(:title_explanation)
        expect(column.explanation).to eq title_explanation.join("\r\n")
      end
      if available_fields.include?(:text_input_type)
        expect(column.input_type).to eq text_input_type
      end
      if available_fields.include?(:date_input_type)
        expect(column.input_type).to eq date_input_type
      end
      if available_fields.include?(:decimal)
        expect(column.min_decimal).to eq min_decimal
        expect(column.max_decimal).to eq max_decimal
        expect(column.initial_decimal).to eq initial_decimal
        expect(column.scale).to eq scale
        expect(column.minus_type).to eq minus_type
      end
      if available_fields.include?(:max_length)
        expect(column.max_length).to eq max_length
      end
      if available_fields.include?(:place_holder)
        expect(column.place_holder).to eq place_holder
      end
      if available_fields.include?(:additional_attr)
        expect(column.additional_attr).to eq additional_attr
      end
      if available_fields.include?(:upload_file_count)
        expect(column.upload_file_count).to eq upload_file_count
      end
      if available_fields.include?(:select_options)
        expect(column.select_options).to eq select_options
      end
      if available_fields.include?(:other_option)
        expect(column.other_state).to eq other_state
        expect(column.other_required).to eq other_required
      end

      #
      # Edit
      #
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") { click_on "edit" }
      end
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") do
          if available_fields.include?(:name)
            fill_in "item[name]", with: name2
          end
          if available_fields.include?(:title)
            fill_in "item[title]", with: title2
          end
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      if available_fields.include?(:name)
        expect(column.name).to eq name2
      end
      if available_fields.include?(:title)
        expect(column.title).to eq title2
      end

      #
      # Delete
      #
      within first(".gws-column-item") do
        wait_for_event_fired("gws:column:removed") do
          page.accept_confirm(I18n.t("ss.confirm.delete")) do
            click_on "delete"
          end
        end
      end
      wait_for_notice I18n.t('ss.notice.deleted')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 0
    end
  end
end
