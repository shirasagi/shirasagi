require 'spec_helper'
require "csv"

describe "article_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create_once :article_node_page, filename: "docs", name: "article" }
  let(:index_path) { article_pages_path site.id, node }
  let(:download_all_path) { download_all_article_pages_path site.id, node }

  feature "#download" do
    background do
      login_cms_user

      create :article_page, cur_site: site, cur_node: node
      create :article_page, cur_site: site, cur_node: node
    end

    scenario "click on download button without check in checkbox" do
      visit index_path
      click_on I18n.t("ss.links.download")
      expect(current_path).to eq download_all_path

      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 2
      expect(csv[0][0]).not_to be_nil
    end

    scenario "click on download button to check in checkbox" do
      visit index_path
      all(".check")[1].click
      expect(page).to have_checked_field 'ids[]'

      click_on I18n.t("ss.links.download")
      expect(current_path).to eq download_all_path

      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true)
      expect(csv.length).to eq 2
      expect(csv[0][0]).not_to be_nil
    end
  end
end
