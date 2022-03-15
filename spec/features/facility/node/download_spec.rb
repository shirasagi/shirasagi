require 'spec_helper'
require "csv"

describe "facility_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:node) { create :facility_node_node, cur_site: site, name: "施設フォルダ" }
  let(:index_path) { facility_pages_path site.id, node }
  let(:download_path) { download_facility_pages_path site.id, node }

  context "#download" do
    before do
      login_cms_user
      create :facility_node_page, cur_site: site, cur_node: node, filename: "#{node.filename}/name_1"
      create :facility_node_page, cur_site: site, cur_node: node, filename: "#{node.filename}/name_2"
    end

    it "click on download button without check in checkbox" do
      visit index_path

      click_on I18n.t("ss.links.download")
      click_on I18n.t("ss.links.download")
      wait_for_download

      csv = ::CSV.read(downloads.first, headers: true, encoding: 'SJIS:UTF-8')
      expect(csv.length).to eq 2
      expect(csv[0][0]).not_to be_nil
    end
  end
end
