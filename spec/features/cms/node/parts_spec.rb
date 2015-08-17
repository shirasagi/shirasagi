require 'spec_helper'

describe "cms_node_parts" do
  subject(:site) { cms_site }
  subject(:node) { create_once :cms_node_page, name: "cms" }
  subject(:item) { Cms::Part.last }
  subject(:index_path) { node_parts_path site.id, node }
  subject(:new_path) { new_node_part_path site.id, node }
  subject(:show_path) { node_part_path site.id, node, item }
  subject(:edit_path) { edit_node_part_path site.id, node, item }
  subject(:delete_path) { delete_node_part_path site.id, node, item }

  before(:all) do
    # TODO:
    # 前提条件:
    # * Cms::Node::PartsController は Cms::PartFilter を include している。
    # * Cms::PartFilter は Cms::NodeFilter を include している。
    # * Cms::NodeFilter#set_item で、"@item.id == @cur_node.id" の場合 404 を発生させている。
    # * つまり、パーツの ID と パーツを入れているフォルダの ID が同じ場合、404 となる。
    #
    # 問題点:
    # 本テストを単独で実行した場合、node の ID は 1 である。
    # 本テストの #new で初めてパーツが作成されるので、その ID は 1 である。
    # このため @item.id = 1, @cur_node.id = 1 となり、条件 "@item.id == @cur_node.id" が成立し 404 が発生する。
    # これを防ぐためにダミーのパーツを作成し、@item.id = 2 となるようにする。
    Cms::Part.create!(site_id: cms_site.id, name: "dummy", basename: "dummy")
  end

  it "without login" do
    visit index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end

    it "#new" do
      visit new_path
      within "form#item-form" do
        fill_in "item[name]", with: "sample"
        fill_in "item[basename]", with: "sample"
        click_button "保存"
      end
      expect(status_code).to eq 200
      expect(current_path).not_to eq new_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#show" do
      visit show_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end

    it "#edit" do
      visit edit_path
      within "form#item-form" do
        fill_in "item[name]", with: "modify"
        click_button "保存"
      end
      expect(current_path).not_to eq sns_login_path
      expect(page).not_to have_css("form#item-form")
    end

    it "#delete" do
      visit delete_path
      within "form" do
        click_button "削除"
      end
      expect(current_path).to eq index_path
    end
  end
end
