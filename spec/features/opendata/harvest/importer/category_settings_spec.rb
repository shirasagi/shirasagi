require 'spec_helper'

describe "opendata_harvest_importer", dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :opendata_node_dataset, name: "opendata_dataset" }
  let(:importer) { create :opendata_harvest_importer, cur_node: node }
  let(:show_path) { opendata_harvest_importer_path site.id, node, importer }

  let!(:category1) { create :opendata_node_category }
  let!(:category2) { create :opendata_node_category }
  let!(:category3) { create :opendata_node_category }

  let!(:estat_category1) { create :opendata_node_estat_category }
  let!(:estat_category2) { create :opendata_node_estat_category }
  let!(:estat_category3) { create :opendata_node_estat_category }

  context "basic crud" do
    before { login_cms_user }

    it "#show" do
      visit show_path
      first("#addon-opendata-agents-addons-harvest-importer_category_setting").click
      within "#addon-opendata-agents-addons-harvest-importer_category_setting" do
        expect(page).to have_link category1.name
        expect(page).to have_link category2.name
        expect(page).to have_link category3.name
        click_on category1.name
      end

      click_on I18n.t("ss.links.new")
      within "form#item-form" do
        fill_in 'item[conditions][][value]', with: unique_id
        click_button I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#download" do
      visit show_path
      first("#addon-opendata-agents-addons-harvest-importer_category_setting").click
      within "#addon-opendata-agents-addons-harvest-importer_category_setting" do
        click_on I18n.t("ss.links.download")
      end
    end

    it "#import" do
      visit show_path
      first("#addon-opendata-agents-addons-harvest-importer_category_setting").click
      within "#addon-opendata-agents-addons-harvest-importer_category_setting" do
        click_on I18n.t("ss.links.import")
      end
    end
  end
end
