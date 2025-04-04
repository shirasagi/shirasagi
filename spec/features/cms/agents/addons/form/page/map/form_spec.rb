require 'spec_helper'

describe "Map Form", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:node) { create :article_node_page, cur_site: site, cur_user: cms_user }
  let(:item) { create(:article_page, cur_site: site, cur_node: node) }

  before do
    login_cms_user
  end

  context "when input contains script tags" do
    before do
      # サイト設定でOpenLayersを選択
      visit cms_site_path(site: site)
      click_on I18n.t("ss.links.edit")
      # wait_for_js_ready
      within "#addon-ss-agents-addons-map_setting" do
        select "OpenLayers", from: "item_map_api"
      end
      click_on I18n.t("ss.buttons.save")
      # wait_for_js_ready

      # 記事ページの編集画面に移動
      visit edit_article_page_path(site: site, cid: node, id: item)
      click_on I18n.t("ss.links.edit")
      # wait_for_js_ready
      click_on I18n.t("board.map_setting")
      # マーカーを設置
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][loc_]", with: "138.263782,36.174713"
        click_on I18n.t("map.buttons.set_marker")
        # wait_for_js_ready
      end
    end

    it "prevents script tags in marker name" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][name]", with: "<script>alert('test')</script>"
        # wait_for_js_ready
        expect(page).to have_selector(".errorExplanation", text: I18n.t("errors.messages.script_not_allowed"))
        expect(find_field("item[map_points][][name]").value).to eq ""
      end
    end

    it "prevents script tags in marker text" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][text]", with: "<script>alert('test')</script>"
        # wait_for_js_ready
        expect(page).to have_selector(".errorExplanation", text: I18n.t("errors.messages.script_not_allowed"))
        expect(find_field("item[map_points][][text]").value).to eq ""
      end
    end

    it "allows valid text in marker name" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][name]", with: "テストマーカー"
        # wait_for_js_ready
        expect(page).not_to have_selector(".errorExplanation")
        expect(find_field("item[map_points][][name]").value).to eq "テストマーカー"
      end
    end

    it "allows valid text in marker text" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][text]", with: "テスト説明"
        # wait_for_js_ready
        expect(page).not_to have_selector(".errorExplanation")
        expect(find_field("item[map_points][][text]").value).to eq "テスト説明"
      end
    end

    it "removes HTML tags from marker name" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][name]", with: "<p>テスト</p>"
        # wait_for_js_ready
        expect(find_field("item[map_points][][name]").value).to eq "テスト"
      end
    end

    it "removes HTML tags from marker text" do
      click_on I18n.t("board.map_point")
      within "#addon-map-agents-addons-page" do
        fill_in "item[map_points][][text]", with: "<p>テスト</p>"
        # wait_for_js_ready
        expect(find_field("item[map_points][][text]").value).to eq "テスト"
      end
    end
  end
end
