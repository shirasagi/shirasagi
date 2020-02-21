require 'spec_helper'

describe "gws_report_forms", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "closed" }

  before { login_gws_user }

  context "file_upload column crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:order) { rand(10) }
    let(:required) { %w(required optional).sample }
    let(:required_label) { I18n.t("ss.options.state.#{required}") }
    let(:tooltips) { Array.new(rand(3..10)) { unique_id } }
    let(:tooltip) { tooltips.join("\n") }
    let(:prefix_label) { unique_id }
    let(:postfix_label) { unique_id }
    let(:place_holder) { unique_id }
    let(:upload_file_count) { rand(1..5) }
    let(:upload_file_count_label) { upload_file_count.to_s }

    it do
      #
      # Create
      #
      visit gws_report_forms_path(site: site)
      click_on form.name
      click_on I18n.t("gws/workflow.columns.index")

      within "#menu" do
        click_on I18n.t("ss.links.new")
        within ".gws-dropdown-menu" do
          click_on I18n.t("gws.columns.gws/file_upload")
        end
      end

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[order]", with: order
        select required_label, from: "item[required]"
        fill_in "item[tooltips]", with: tooltip
        fill_in "item[prefix_label]", with: prefix_label
        fill_in "item[postfix_label]", with: postfix_label
        fill_in "item[place_holder]", with: place_holder
        select upload_file_count_label, from: "item[upload_file_count]"

        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column.name).to eq name
      expect(column.order).to eq order
      expect(column.required).to eq required
      expect(column.tooltips).to eq tooltips
      expect(column.prefix_label).to eq prefix_label
      expect(column.postfix_label).to eq postfix_label
      expect(column.place_holder).to eq place_holder
      expect(column.upload_file_count).to eq upload_file_count

      #
      # Edit
      #
      click_on I18n.t("ss.links.edit")

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      form.reload
      expect(form.columns.count).to eq 1

      column = form.columns.first
      expect(column.name).to eq name2
      expect(column.order).to eq order
      expect(column.required).to eq required
      expect(column.tooltips).to eq tooltips
      expect(column.prefix_label).to eq prefix_label
      expect(column.postfix_label).to eq postfix_label
      expect(column.place_holder).to eq place_holder
      expect(column.upload_file_count).to eq upload_file_count

      #
      # Delete
      #
      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      form.reload
      expect(form.columns.count).to eq 0
    end
  end
end
