require 'spec_helper'

describe "cms_search_contents_pages", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:user) { cms_user }
  let!(:layout1) { create :cms_layout }
  let!(:layout2) { create :cms_layout }
  let!(:node) { create :cms_node }
  let!(:page1) do
    html1 = "<div>html1</div>"
    create(:cms_page, cur_site: site, user: user, layout: layout1, html: html1, state: "public")
  end
  let!(:page2) do
    html2 = "<div>html2</div>"
    create(:cms_page, cur_site: site, user: user, layout: layout2, html: html2, state: "public")
  end

  before do
    login_cms_user
  end

  context "search with layout" do
    it do
      visit cms_search_contents_pages_path(site: site)

      within "form.search-pages" do
        wait_cbox_open { click_on I18n.t("cms.apis.layouts.index") }
      end
      wait_for_cbox do
        wait_cbox_close { click_on layout1.name }
      end
      within "form.search-pages" do
        expect(page).to have_content(layout1.name)

        click_on I18n.t('ss.buttons.search')
      end

      expect(page).to have_css(".search-count", text: I18n.t("cms.search_contents_count", count: 1))
      expect(page).to have_css("div.info a.title", text: page1.name)
    end
  end
end
