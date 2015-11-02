require 'spec_helper'

describe "opendata_agents_nodes_my_dataset", dbscope: :example do
  let(:site) { cms_site }
  let(:member) { opendata_member(site: site) }
  let!(:node_member) { create :opendata_node_member }
  let!(:node_search_dataset) { create_once :opendata_node_search_dataset, basename: "dataset/search" }
  let!(:node_dataset) { create :opendata_node_dataset }

  let!(:upper_html) { '<a href="new/">新規作成</a><table class="opendata-datasets datasets"><tbody>' }
  let!(:node_mypage) { create :opendata_node_mypage, filename: "mypage" }
  let!(:node_my_dataset) do
    create :opendata_node_my_dataset, filename: "#{node_mypage.filename}/dataset", upper_html: upper_html
  end

  let!(:node_login) { create :member_node_login, redirect_url: node_my_dataset.url }

  let!(:category) { create :opendata_node_category, name: "カテゴリー０１" }
  let!(:node_area) { create :opendata_node_area, name: "地域Ａ" }

  let!(:node_search) { create :opendata_node_search_dataset }

  let(:index_url) { ::URI.parse "http://#{site.domain}#{node_my_dataset.url}" }
  # let(:new_path) { "#{node_myidea.url}new/" }
  # let(:show_path) { "#{node_myidea.url}1/" }
  # let(:edit_path) { "#{node_myidea.url}1/edit/" }
  # let(:delete_path) { "#{node_myidea.url}1/delete/" }

  let(:item_name) { "データセット０１" }
  let(:item_name2) { "データセット０２" }
  let(:item_text) { "データセット内容" }

  before do
    login_opendata_member(site, node_login, member)
  end

  after do
    logout_opendata_member(site, node_login, member)
  end

  describe "#index" do
    let!(:dataset) { create :opendata_dataset, node: node_dataset, member_id: member.id }

    it do
      visit index_url
      expect(current_path).to eq index_url.path
      expect(status_code).to eq 200
      within "table.opendata-datasets" do
        expect(page).to have_content dataset.name
      end
    end
  end

  it "#new_create_edit_delete" do
    visit index_url
    click_link "新規作成"
    expect(status_code).to eq 200

    fill_in "item_name", with: item_name
    fill_in "item_text", with: item_text
    check category.name
    click_button "公開保存"
    expect(status_code).to eq 200

    within "table.opendata-datasets" do
      expect(page).to have_content item_name
    end

    click_link item_name
    expect(status_code).to eq 200

    within "table.opendata-dataset" do
      expect(page).to have_content item_name
      expect(page).to have_content item_text
      expect(page).to have_content category.name
    end

    click_link "編集"
    expect(status_code).to eq 200
    within "form#item-form" do
      fill_in "item_name", with: item_name2
    end

    click_button "公開保存"
    expect(status_code).to eq 200

    within "table.opendata-dataset" do
      expect(page).to have_content item_name2
      expect(page).to have_content item_text
      expect(page).to have_content category.name
    end

    click_link "削除"
    click_button "削除"
    expect(status_code).to eq 200
    expect(current_path).to eq index_url.path

    within "table.opendata-datasets" do
      expect(page).not_to have_content item_name2
    end
  end
end
