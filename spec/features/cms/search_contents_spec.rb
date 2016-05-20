require 'spec_helper'

describe "cms_search", dbscope: :example do
  subject(:site) { cms_site }
  subject(:pages_index_path) { cms_search_contents_pages_path site.id }
  subject(:html_index_path) { cms_search_contents_html_path site.id }

  it "without login" do
    visit html_index_path
    expect(current_path).to eq sns_login_path
  end

  it "without auth" do
    login_ss_user
    visit html_index_path
    expect(status_code).to eq 403
  end

  context "with auth" do
    before { login_cms_user }

    context "search_contents_pages" do
      before(:each) do
        create(:cms_page, cur_site: site, name: "[TEST]A", filename: "A.html", state: "public")
        create(:article_page, cur_site: site, name: "[TEST]B", filename: "base/B.html", state: "public")
        create(:event_page, cur_site: site, name: "[TEST]C", filename: "base/C.html", state: "closed")
        create(:faq_page, cur_site: site, name: "[TEST]D", filename: "base/D.html", state: "closed")
      end

      it "search with empty conditions" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        click_button "検索"
        expect(status_code).to eq 200
        expect(page).to have_css(".search-count", text: "4 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end

      it "search with name" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          fill_in "s_name", with: "A"
          click_button "検索"
        end
        expect(status_code).to eq 200
        expect(page).to have_css(".search-count", text: "1 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end

      it "search with filename" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          fill_in "s_filename", with: "base/"
          click_button "検索"
        end
        expect(status_code).to eq 200
        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end

      it "search with state" do
        visit pages_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.search-pages" do
          select "公開", from: "s_state"
          click_button "検索"
        end
        expect(status_code).to eq 200
        expect(page).to have_css(".search-count", text: "2 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        within "form.search-pages" do
          select "非公開", from: "s_state"
          click_button "検索"
        end
        expect(status_code).to eq 200
        expect(page).to have_css(".search-count", text: "2 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end

      it "search with released_or_updated" do
        Timecop.travel(3.days.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          page = Cms::Page.where(name: "[TEST]D").first
          page.state = "public"
          page.save
        end

        Timecop.travel(6.days.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          page = Cms::Page.where(name: "[TEST]A").first
          page.html = "update"
          page.save
        end

        Timecop.travel(1.day.from_now) do
          login_cms_user
          visit pages_index_path
          expect(current_path).not_to eq sns_login_path
          start = Time.zone.now
          close = start.advance(days: 6)
          start = start.strftime("%Y/%m/%d %H:%M:%S")
          close = close.strftime("%Y/%m/%d %H:%M:%S")

          within "form.search-pages" do
            fill_in "s_released_start", with: start
            fill_in "s_released_close", with: close
            fill_in "s_updated_start", with: ""
            fill_in "s_updated_close", with: ""
            click_button "検索"
          end
          expect(status_code).to eq 200
          expect(page).to have_css(".search-count", text: "1 件の検索結果")
          expect(page).to have_css("div.info a.title", text: "[TEST]D")

          within "form.search-pages" do
            fill_in "s_released_start", with: ""
            fill_in "s_released_close", with: ""
            fill_in "s_updated_start", with: start
            fill_in "s_updated_close", with: close
            click_button "検索"
          end
          expect(status_code).to eq 200
          expect(page).to have_css(".search-count", text: "2 件の検索結果")
          expect(page).to have_css("div.info a.title", text: "[TEST]A")
          expect(page).to have_css("div.info a.title", text: "[TEST]D")
        end
      end
    end

    context "search_contents_html", js: true do
      before(:each) do
        create(:article_page, name: "[TEST]top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST]child",   html: '<a href="/top/child/">anchor2</a><p>くらし\r\nガイド</p>')
        create(:article_page, name: "[TEST]1.html",  html: '<a href="/top/child/1.html">anchor3</a>')
        create(:article_page, name: "[TEST]nothing", html: '')
      end

      it "replace_html with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "くらし"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: "くらし"
          fill_in "replacement", with: "戸籍"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: "戸籍"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1.html")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")
      end

      it "replace_html with url" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "/top/child/"
          check "option-url"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).to     have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: "/top/child/"
          fill_in "replacement", with: "/kurashi/koseki/"
          check "option-url"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).to     have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: "/kurashi/koseki/"
          check "option-url"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).to     have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")
      end

      it "replace_html with regexp" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: '<p>.+?<\/p>'
          check "option-regexp"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: '<p>.+?<\/p>'
          fill_in "replacement", with: "<s>正規表現</s>"
          check "option-regexp"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")

        within "form.index-search" do
          fill_in "keyword", with: '<s>.+?<\/s>'
          check "option-regexp"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]child")
        expect(page).not_to have_css(".result table a", text: "[TEST]1")
        expect(page).not_to have_css(".result table a", text: "[TEST]nothing")
      end
    end

    context "ss-909", js: true do
      # see: https://github.com/shirasagi/shirasagi/issues/909
      before(:each) do
        create(:article_page, name: "[TEST]top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST]TOP",     html: '<a href="/TOP/" class="TOP">ANCHOR</a>')
      end

      it "replace_html with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "anchor"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).to     have_css(".result table a", text: "[TEST]top")
        expect(page).not_to have_css(".result table a", text: "[TEST]TOP")

        within "form.index-search" do
          fill_in "keyword", with: "anchor"
          fill_in "replacement", with: "アンカー"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).to     have_css(".result table a", text: "[TEST]top")
        expect(page).not_to have_css(".result table a", text: "[TEST]TOP")
      end

      it "replace_url with string" do
        visit html_index_path
        expect(current_path).not_to eq sns_login_path
        within "form.index-search" do
          fill_in "keyword", with: "/TOP/"
          check "option-url"
          click_button "検索"
        end
        wait_for_ajax
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]TOP")

        within "form.index-search" do
          fill_in "keyword", with: "/TOP/"
          fill_in "replacement", with: "/kurashi/"
          check "option-url"
          click_button "全置換"
        end
        expect(status_code).to eq 200
        expect(page).not_to have_css(".result table a", text: "[TEST]top")
        expect(page).to     have_css(".result table a", text: "[TEST]TOP")
      end
    end
  end
end
