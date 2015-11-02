require 'spec_helper'

describe "opendata_agents_nodes_my_dataset_resources", dbscope: :example do
  let(:site) { cms_site }
  let(:member) { opendata_member(site: site) }
  let!(:node_member) { create :opendata_node_member }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, basename: "dataset/search" }
  let!(:node_dataset) { create :opendata_node_dataset }

  let!(:node_mypage) { create :opendata_node_mypage, filename: "mypage" }
  let!(:node_my_dataset) { create :opendata_node_my_dataset, filename: "#{node_mypage.filename}/dataset" }
  let!(:node_login) { create :member_node_login, redirect_url: node_my_dataset.url }

  let!(:category) { create :opendata_node_category, name: "カテゴリー０１" }
  let!(:node_area) { create :opendata_node_area, name: "地域Ａ" }

  let!(:node_search) { create :opendata_node_search_dataset }
  let!(:dataset) { create :opendata_dataset, node: node_dataset, member_id: member.id }

  let(:license_logo_file_path) { Rails.root.join("spec", "fixtures", "ss", "logo.png") }
  let(:license_logo_file) { Fs::UploadedFile.create_from_file(license_logo_file_path, basename: "spec") }
  let!(:license) { create(:opendata_license, site: site, file: license_logo_file) }

  let(:index_url) { ::URI.parse "http://#{site.domain}#{node_my_dataset.url}" }

  let(:item_name) { "リソース０１" }
  let(:item_name2) { "リソース０２" }
  let(:item_text) { "リソース内容０１" }
  let(:item_text2) { "リソース内容０２" }

  before do
    login_opendata_member(site, node_login, member)
  end

  after do
    logout_opendata_member(site, node_login, member)
  end

  describe "create/edit/delete resource" do
    it do
      visit index_url
      expect(current_path).to eq index_url.path
      expect(status_code).to eq 200
      click_link dataset.name
      click_link 'リソースを管理する'
      click_link '新規作成'
      expect(status_code).to eq 200

      within "form#item-form" do
        fill_in "item_name", with: item_name
        fill_in "item_format", with: "CSV"
        fill_in "item_text", with: item_text
        attach_file "item[in_file]", "#{Rails.root}/spec/fixtures/opendata/shift_jis.csv"
        select  license.name, from: "item_license_id"
        click_button "公開保存"
      end
      expect(status_code).to eq 200

      within "table.opendata-resources" do
        expect(page).to have_content(item_name)
        click_link item_name
      end
      expect(status_code).to eq 200

      within "nav.menu" do
        click_link '編集'
      end
      expect(status_code).to eq 200

      within "form#item-form" do
        fill_in "item_name", with: item_name2
        fill_in "item_text", with: item_text2
        click_button "公開保存"
      end
      expect(status_code).to eq 200

      within "table.opendata-dataset-resources" do
        expect(page).not_to have_content(item_name)
        expect(page).to have_content(item_name2)
      end
      within "nav.menu" do
        click_link '削除'
      end
      within "form#item-form" do
        click_button '削除'
      end
      expect(status_code).to eq 200

      within "table.opendata-resources" do
        expect(page).not_to have_content(item_name)
        expect(page).not_to have_content(item_name2)
      end
    end
  end
end
