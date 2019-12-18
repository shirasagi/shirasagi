require 'spec_helper'

describe Opendata::Dataset::ResourcePreviewHistoryArchivesController, type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create(:opendata_node_dataset, name: "opendata_dataset") }
  let(:archive1_name) { "#{unique_id}.zip" }
  let(:archive1_filename) { "#{unique_id}.zip" }
  let(:zip_path) { Rails.root.join("spec/fixtures/opendata/dataset_import.zip") }
  let!(:archive1) do
    Opendata::ResourcePreviewHistory::ArchiveFile.create_empty!(
      cur_site: site, name: archive1_name, filename: archive1_filename, content_type: 'application/zip'
    ) do |file|
      ::FileUtils.cp(zip_path, file.path)
    end
  end

  before { login_cms_user }

  describe "basic crud" do
    it do
      visit opendata_dataset_history_preview_archives_path(site: site, cid: node)
      click_on archive1.humanized_name
      click_on I18n.t("ss.buttons.download")

      wait_for_download
      expect(::File.binread(downloads.first)).to eq ::File.binread(zip_path)

      click_on I18n.t("ss.links.delete")
      within "form" do
        click_on I18n.t("ss.buttons.delete")
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect { archive1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end

  describe "keyword search" do
    it do
      visit opendata_dataset_history_preview_archives_path(site: site, cid: node)
      within ".index-search" do
        fill_in "s[keyword]", with: archive1.name
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item .title", text: archive1.humanized_name)

      within ".index-search" do
        fill_in "s[keyword]", with: archive1.filename
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_css(".list-item .title", text: archive1.humanized_name)

      within ".index-search" do
        fill_in "s[keyword]", with: unique_id
        click_on I18n.t("ss.buttons.search")
      end
      expect(page).to have_no_css(".list-item .title", text: archive1.humanized_name)
    end
  end

  describe "bulk delete" do
    it do
      visit opendata_dataset_history_preview_archives_path(site: site, cid: node)
      first(".list-head input[type='checkbox']").click
      page.accept_confirm do
        within ".list-head-action" do
          click_on I18n.t("ss.links.delete")
        end
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.deleted'))

      expect { archive1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
    end
  end
end
