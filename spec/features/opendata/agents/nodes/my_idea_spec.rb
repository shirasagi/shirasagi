require 'spec_helper'

describe "opendata_agents_nodes_my_idea", dbscope: :example do
  let(:site) { cms_site }
  let!(:node) { create_once :opendata_node_idea, name: "opendata_agents_nodes_idea" }
  let!(:member) { create_once :opendata_node_member }

  let!(:node_mypage) { create_once :opendata_node_mypage, filename: "mypage" }
  let!(:node_myidea) { create_once :opendata_node_my_idea, filename: "#{node_mypage.filename}/idea" }

  let!(:category) { create_once :opendata_node_category, name: "カテゴリー０１" }
  let!(:area) { create_once :opendata_node_area, name: "地域Ａ" }
  let(:node_idea) { create_once :opendata_node_idea, name: "opendata_idea" }

#  let(:idea) do
#    create_once :opendata_idea,
#      filename: "#{node_idea.filename}/1.html",
#      category_ids: [ category.id ],
#      area_ids: [ area.id ]
#  end

  let!(:node_search) { create :opendata_node_search_idea }
  let!(:node_auth) { node_mypage }

  let(:index_path) { "#{node_myidea.url}index.html" }
  let(:new_path) { "#{node_myidea.url}new/" }
  let(:show_path) { "#{node_myidea.url}1/" }
  let(:edit_path) { "#{node_myidea.url}1/edit/" }
  let(:delete_path) { "#{node_myidea.url}1/delete/" }

  let(:item_name) { "アイデア０１" }
  let(:item_text) { "アイデア内容" }

  before do
    login_opendata_member(site, node_auth)
  end

  it "#index" do
    visit "http://#{site.domain}#{index_path}"
    expect(current_path).to eq index_path
  end

  it "#new_create_edit_delete" do

    visit "http://#{site.domain}#{index_path}"
    click_link "新規作成"
    expect(current_path).to eq new_path

    fill_in "item_name", with: item_name
    fill_in "item_text", with: item_text
    check category.name
    click_button "保存"
    expect(current_path).to eq node_myidea.url

    click_link item_name
    expect(current_path).to eq show_path

    click_link "編集"
    expect(current_path).to eq edit_path

    click_button "保存"
    expect(current_path).to eq show_path

    click_link "削除"
    expect(current_path).to eq delete_path

    click_button "削除"
    expect(current_path).to eq node_myidea.url

  end

end
