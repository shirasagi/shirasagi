require 'spec_helper'

describe "cms_page_search", dbscope: :example do
  let(:site) { cms_site }
  let(:index_path) { cms_page_searches_path site.id }

  context "without auth" do
    it "without login" do
      visit index_path
      expect(current_path).to eq sns_login_path
    end

    it "without auth" do
      login_ss_user
      visit index_path
      expect(status_code).to eq 403
    end
  end

  context "basic crud" do
    let(:name) { unique_id }
    let(:name2) { unique_id }
    let(:search_name) { unique_id }

    before { login_cms_user }

    it do
      visit index_path
      click_on "新規作成"

      within "form#item-form" do
        fill_in "item[name]", with: name
        fill_in "item[search_name]", with: search_name
        click_on "保存"
      end

      within "#addon-basic .addon-body .see" do
        expect(page).to have_css("dd", text: name)
        expect(page).to have_css("dd", text: search_name)
      end

      expect(Cms::PageSearch.site(site).count).to eq 1
      Cms::PageSearch.site(site).first.tap do |item|
        expect(item.name).to eq name
        expect(item.order).to eq 0
        expect(item.search_name).to eq search_name
      end

      click_on "サイト管理"
      expect(page).to have_css("nav.main-navi h2 a.icon-conv", text: name)

      visit index_path
      click_on name
      click_on "編集する"

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_on "保存"
      end

      expect(Cms::PageSearch.site(site).count).to eq 1
      Cms::PageSearch.site(site).first.tap do |item|
        expect(item.name).to eq name2
        expect(item.order).to eq 0
        expect(item.search_name).to eq search_name
      end

      click_on "サイト管理"
      expect(page).to have_css("nav.main-navi h2 a.icon-conv", text: name2)

      visit index_path
      click_on name2
      click_on "削除する"
      click_on "削除"

      expect(Cms::PageSearch.site(site).count).to eq 0
    end
  end

  context "search" do
    let(:name) { unique_id }

    before do
      node = create(:category_node_page, filename: 'base')
      create(:cms_page, cur_site: site, name: "[TEST]A", filename: "A.html", state: "public")
      create(:article_page, cur_site: site, cur_node: node, name: "[TEST]B", filename: "B.html", state: "public")
      create(:event_page, cur_site: site, cur_node: node, name: "[TEST]C", filename: "C.html", state: "closed")
      create(:faq_page, cur_site: site, cur_node: node, name: "[TEST]D", filename: "D.html", state: "closed")
    end

    before { login_cms_user }

    context "with name" do
      it do
        visit index_path
        click_on "新規作成"

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[search_name]", with: "A"
          click_on "保存"
        end

        click_on "検索"

        expect(page).to have_css(".search-count", text: "1 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end
    end

    context "with filename" do
      it do
        visit index_path
        click_on "新規作成"

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[search_filename]", with: "base/"
          click_on "保存"
        end

        click_on "検索"

        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end
    end
  end
end
