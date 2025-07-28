require 'spec_helper'

describe "opendata_harvest_importer", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :opendata_node_dataset, name: "opendata_dataset" }
  let(:item) { create :opendata_harvest_importer, cur_node: node }
  let(:index_path) { opendata_harvest_importers_path site.id, node }
  let(:new_path) { new_opendata_harvest_importer_path site.id, node }
  let(:show_path) { opendata_harvest_importer_path site.id, node, item }
  let(:edit_path) { edit_opendata_harvest_importer_path site.id, node, item }
  let(:delete_path) { delete_opendata_harvest_importer_path site.id, node, item }
  let(:import_path) { import_opendata_harvest_importer_path site.id, node, item }
  let(:purge_path) { purge_opendata_harvest_importer_path site.id, node, item }

  context "basic crud" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[source_url]", with: "http://sample.example.jp"
        select "Shirasagi API", from: 'item[api_type]'
      end
      click_on I18n.t("ss.buttons.save")
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#show" do
      visit show_path
      expect(page).to have_css("#addon-basic", text: item.name)
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
      end
      click_on I18n.t("ss.buttons.save")
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t('ss.notice.deleted')
    end

    it "#import" do
      visit import_path
      page.accept_confirm do
        click_on I18n.t("ss.buttons.run")
      end
      wait_for_notice I18n.t("ss.notice.started_import")
      expect(enqueued_jobs.size).to eq 1
    end

    it "#purge" do
      visit purge_path
      page.accept_confirm do
        click_on I18n.t("ss.buttons.run")
      end
      wait_for_notice I18n.t("ss.notice.started_purge")
      expect(enqueued_jobs.size).to eq 1
    end
  end
end
