require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "closed" }

  before { login_gws_user }

  context "number_field column crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:order) { rand(10) }
    let(:required) { %w(required optional).sample }
    let(:required_label) { I18n.t("ss.options.state.#{required}") }
    let(:tooltips) { Array.new(rand(3..10)) { unique_id } }
    let(:tooltip) { tooltips.join("\n") }
    let(:prefix_label) { unique_id[0, 10] }
    let(:postfix_label) { unique_id[0, 10] }
    let(:prefix_explanation) { unique_id[0, 10] }
    let(:postfix_explanation) { unique_id[0, 10] }
    let(:min_decimal) { rand(10) }
    let(:max_decimal) { min_decimal + rand(10) }
    let(:initial_decimal) { (min_decimal + max_decimal) / 2 }
    let(:scale) { rand(10) }
    let(:minus_type) { %w(normal filled_triangle triangle).sample }
    let(:minus_type_label) { I18n.t("gws/column.options.minus_type.#{minus_type}") }
    let(:max_length) { rand(10) }
    let(:place_holder) { unique_id }
    let(:additional_attr) { unique_id }

    it do
      #
      # Create
      #
      visit gws_report_forms_path(site: site)
      click_on form.name
      click_on I18n.t("gws/workflow.columns.index")

      within ".gws-column-list-toolbar[data-placement='top']" do
        wait_for_event_fired("gws:column:added") { click_on I18n.t("mongoid.models.gws/column/number_field") }
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
          fill_in "item[name]", with: name
          fill_in "item[order]", with: order
          select required_label, from: "item[required]"
          fill_in "item[tooltips]", with: tooltip
          fill_in "item[prefix_label]", with: prefix_label
          fill_in "item[postfix_label]", with: postfix_label
          fill_in "item[prefix_explanation]", with: prefix_explanation
          fill_in "item[postfix_explanation]", with: postfix_explanation

          fill_in "item[min_decimal]", with: min_decimal
          fill_in "item[max_decimal]", with: max_decimal
          fill_in "item[initial_decimal]", with: initial_decimal
          fill_in "item[scale]", with: scale
          select minus_type_label, from: "item[minus_type]"

          fill_in "item[max_length]", with: max_length
          fill_in "item[place_holder]", with: place_holder
          fill_in "item[additional_attr]", with: additional_attr

          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column.name).to eq name
      expect(column.order).to eq order
      expect(column.required).to eq required
      expect(column.tooltips).to eq tooltips
      expect(column.prefix_label).to eq prefix_label
      expect(column.postfix_label).to eq postfix_label
      expect(column.prefix_explanation).to eq prefix_explanation
      expect(column.postfix_explanation).to eq postfix_explanation
      expect(column.min_decimal).to eq min_decimal
      expect(column.max_decimal).to eq max_decimal
      expect(column.initial_decimal).to eq initial_decimal
      expect(column.scale).to eq scale
      expect(column.minus_type).to eq minus_type
      expect(column.max_length).to eq max_length
      expect(column.place_holder).to eq place_holder
      expect(column.additional_attr).to eq additional_attr

      #
      # Edit
      #
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") { click_on "edit" }
      end
      within first(".gws-column-item") do
        wait_for_event_fired("turbo:frame-load") do
          fill_in "item[name]", with: name2
          click_on I18n.t("ss.buttons.save")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
      clear_notice

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column.name).to eq name2
      expect(column.order).to eq order
      expect(column.required).to eq required
      expect(column.tooltips).to eq tooltips
      expect(column.prefix_label).to eq prefix_label
      expect(column.postfix_label).to eq postfix_label
      expect(column.prefix_explanation).to eq prefix_explanation
      expect(column.postfix_explanation).to eq postfix_explanation
      expect(column.min_decimal).to eq min_decimal
      expect(column.max_decimal).to eq max_decimal
      expect(column.initial_decimal).to eq initial_decimal
      expect(column.scale).to eq scale
      expect(column.minus_type).to eq minus_type
      expect(column.max_length).to eq max_length
      expect(column.place_holder).to eq place_holder
      expect(column.additional_attr).to eq additional_attr

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
