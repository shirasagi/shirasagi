require 'spec_helper'

describe "cms_search", dbscope: :example do
  subject(:site) { cms_site }
  subject(:index_path) { cms_search_path site.host }

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

    context "search_contents", js: true do
      before(:each) do
        create(:article_page, name: "[TEST] top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST] child",   html: '<a href="/top/child/">anchor2</a><p>くらし\r\nガイド</p>')
        create(:article_page, name: "[TEST] 1.html",  html: '<a href="/top/child/1.html">anchor3</a>')
        create(:article_page, name: "[TEST] nothing", html: '')
      end

      it "replace_html_with_string" do
        visit index_path
        within "form.index-search" do
          fill_in "keyword", with: "くらし"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: "くらし"
          fill_in "replacement", with: "戸籍"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: "戸籍"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")
      end

      it "replace_html_with_url" do
        visit index_path
        within "form.index-search" do
          fill_in "keyword", with: "/top/child/"
          check "option-url"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).to     have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: "/top/child/"
          fill_in "replacement", with: "/kurashi/koseki/"
          check "option-url"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).to     have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: "/kurashi/koseki/"
          check "option-url"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).to     have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")
      end

      it "replace_html_with_regexp" do
        visit index_path
        within "form.index-search" do
          fill_in "keyword", with: '<p>.+?<\/p>'
          check "option-regexp"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: '<p>.+?<\/p>'
          fill_in "replacement", with: "<s>正規表現</s>"
          check "option-regexp"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")

        within "form.index-search" do
          fill_in "keyword", with: '<s>.+?<\/s>'
          check "option-regexp"
          click_button "検索"
        end
        wait_for_ajax(".result table")
        expect(page).not_to have_css(".result table a", text: "[TEST] top")
        expect(page).to     have_css(".result table a", text: "[TEST] child")
        expect(page).not_to have_css(".result table a", text: "[TEST] 1")
        expect(page).not_to have_css(".result table a", text: "[TEST] nothing")
      end
   end
  end
end
