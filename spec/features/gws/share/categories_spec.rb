require 'spec_helper'

describe "gws_share_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:index_path) { gws_share_categories_path site }

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:color) { "#481357" }

    before { login_gws_user }

    it do
      visit index_path
      expect(current_path).to eq index_path

      #
      # create
      #
      within ".nav-menu" do
        click_on I18n.t('ss.links.new')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[color]", with: color + "\n"
        click_button I18n.t('ss.buttons.save')
      end

      category = Gws::Share::Category.site(site).find_by(name: name)
      expect(category.name).to eq name
      expect(category.color).to eq color

      expect(page).to have_css("div.addon-body dd", text: name)

      #
      # edit
      #
      within ".nav-menu" do
        click_link I18n.t('ss.links.edit')
      end
      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end

      category.reload
      expect(category.name).to eq name2
      expect(category.color).to eq color

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

      category = Gws::Share::Category.site(site).where(name: name).first
      expect(category).to be_nil

      expect(page).to have_no_css("div.info")
    end
  end
end
