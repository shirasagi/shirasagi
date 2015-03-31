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

    context "search pages" do
      before(:each) do
        create(:article_page, name: "[TEST] top",     html: '<a href="/top/" class="top">anchor</a>')
        create(:article_page, name: "[TEST] child",   html: "<a href=\"/top/child/\">anchor2</a>\r\n<p>p\r\ntag</p>")
        create(:article_page, name: "[TEST] 1",       html: '<a href="/top/child/1.html">anchor3</a>')
        create(:article_page, name: "[TEST] nothing", html: '')
      end

      it "search_html_with_url" do
        visit cms_search_html_path site.host, s: { keyword: "/top/", option: "url" }
        expect(status_code).to eq 200
        expect(page).to     have_css("a", text: "[TEST] top")
        expect(page).to     have_css("a", text: "[TEST] child")
        expect(page).to     have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")

        visit cms_search_html_path site.host, s: { keyword: "/top/child/", option: "url" }
        expect(status_code).to eq 200
        expect(page).not_to have_css("a", text: "[TEST] top")
        expect(page).to     have_css("a", text: "[TEST] child")
        expect(page).to     have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")

        visit cms_search_html_path site.host, s: { keyword: "/top/child/1.html", option: "url" }
        expect(status_code).to eq 200
        expect(page).not_to have_css("a", text: "[TEST] top")
        expect(page).not_to have_css("a", text: "[TEST] child")
        expect(page).to     have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")
      end

      it "search_html_with_regexp" do
        visit cms_search_html_path site.host, s: { keyword: 'class=\"top\"', option: "regexp" }
        expect(status_code).to eq 200
        expect(page).to     have_css("a", text: "[TEST] top")
        expect(page).not_to have_css("a", text: "[TEST] child")
        expect(page).not_to have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")

        visit cms_search_html_path site.host, s: { keyword: 'anchor\d', option: "regexp" }
        expect(status_code).to eq 200
        expect(page).not_to have_css("a", text: "[TEST] top")
        expect(page).to     have_css("a", text: "[TEST] child")
        expect(page).to     have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")

        visit cms_search_html_path site.host, s: { keyword: '<p>.+?<\/p>', option: "regexp" }
        expect(status_code).to eq 200
        expect(page).not_to have_css("a", text: "[TEST] top")
        expect(page).to     have_css("a", text: "[TEST] child")
        expect(page).not_to have_css("a", text: "[TEST] 1")
        expect(page).not_to have_css("a", text: "[TEST] nothing")
      end
    end
  end
end
