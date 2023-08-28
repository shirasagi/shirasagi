require 'spec_helper'

describe "gws_report_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:color) { "#481357" }
    let(:order) { rand(10) }

    before { login_gws_user }

    it do
      visit gws_report_categories_path(site: site)

      #
      # create
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[color]", with: color + "\n"
        fill_in "item[order]", with: order
        click_on I18n.t('ss.buttons.save')
      end

      category = Gws::Report::Category.site(site).find_by(name: name)
      expect(category.name).to eq name
      expect(category.color).to eq color
      expect(category.order).to eq order

      expect(page).to have_css("div.addon-body dd", text: name)

      #
      # edit
      #
      within ".nav-menu" do
        click_link I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on I18n.t('ss.buttons.save')
      end

      category.reload
      expect(category.name).to eq name2
      expect(category.color).to eq color
      expect(category.order).to eq order

      expect(page).to have_css("div.addon-body dd", text: name2)

      #
      # index
      #
      within ".nav-menu" do
        click_link I18n.t('ss.links.back_to_index')
      end
      within "div.info" do
        expect(page).to have_css("a.title", text: name2)
        click_link name2
      end

      #
      # delete
      #
      within ".nav-menu" do
        click_link I18n.t('ss.links.delete')
      end
      click_button I18n.t('ss.buttons.delete')

      category = Gws::Report::Category.site(site).where(name: name).first
      expect(category).to be_nil

      expect(page).to have_no_css("div.info")
    end
  end
end
