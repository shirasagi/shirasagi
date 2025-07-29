require 'spec_helper'

describe "cms_search_contents_html", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:html_index_path) { cms_search_contents_html_path site.id }

  before do
    login_cms_user
  end

  context "ss-909" do
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
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_js_ready
      expect(page).to have_css(".result table a", text: "[TEST]top")
      expect(page).to have_no_css(".result table a", text: "[TEST]TOP")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: "anchor"
          fill_in "replacement", with: "アンカー"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end

    it "replace_url with string" do
      visit html_index_path
      expect(current_path).not_to eq sns_login_path
      within "form.index-search" do
        fill_in "keyword", with: "/TOP/"
        check "option-url"
        click_button I18n.t('ss.buttons.search')
      end
      wait_for_js_ready
      expect(page).to have_no_css(".result table a", text: "[TEST]top")
      expect(page).to have_css(".result table a", text: "[TEST]TOP")

      page.accept_confirm do
        within "form.index-search" do
          fill_in "keyword", with: "/TOP/"
          fill_in "replacement", with: "/kurashi/"
          check "option-url"
          click_button I18n.t("ss.buttons.replace_all")
        end
      end
      wait_for_notice I18n.t('ss.notice.saved')
    end
  end
end
