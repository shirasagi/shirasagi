require 'spec_helper'

describe "facility_node_searches", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:node) { create :cms_node }
  let(:item) { create :facility_node_search, filename: "#{node.filename}/name" }
  let(:index_path)  { facility_searches_path site.id, node }
  let(:new_path)    { "#{index_path}/new" }
  let(:show_path)   { "#{index_path}/#{item.id}" }
  let(:edit_path)   { "#{index_path}/#{item.id}/edit" }
  let(:delete_path) { "#{index_path}/#{item.id}/delete" }
  let(:addon_titles) { page.all("form .addon-head h2").map(&:text).sort }
  let(:expected_addon_titles) { %w(フォルダー設定 メタ情報 公開予約の既定値 公開設定 基本情報 施設の用途 施設の種類 施設地域 施設情報 権限 追加情報).sort }

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
