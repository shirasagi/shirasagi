require 'spec_helper'

describe "gws_workflow2_form_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  before { login_gws_user }

  context "basic crud" do
    let(:name) { "name-#{unique_id}" }
    let(:name2) { "name-#{unique_id}" }
    let(:hex_decimal) { "0123456789abcdef".chars }
    let(:color) { unique_color }
    let(:order) { rand(10..20) }

    it do
      #
      # Create
      #
      visit gws_workflow2_form_categories_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.new")
      end
      wait_for_all_color_pickers_ready
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in_color "item[color]", with: color[1..-1]
        fill_in "item[order]", with: order

        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Category.all.count).to eq 1
      Gws::Workflow2::Form::Category.all.first.tap do |item|
        expect(item.site_id).to eq site.id
        expect(item.name).to eq name
        expect(item.color).to eq color
        expect(item.order).to eq order
      end

      #
      # Update
      #
      visit gws_workflow2_form_categories_path(site: site)
      click_on name
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      wait_for_all_color_pickers_ready
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")

      expect(Gws::Workflow2::Form::Category.all.count).to eq 1
      Gws::Workflow2::Form::Category.all.first.tap do |item|
        expect(item.name).to eq name2
      end

      #
      # Delete
      #
      visit gws_workflow2_form_categories_path(site: site)
      click_on name2
      within ".nav-menu" do
        click_on I18n.t("ss.links.delete")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect(Gws::Workflow2::Form::Category.all.count).to eq 0
    end
  end
end
