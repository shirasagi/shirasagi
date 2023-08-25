require 'spec_helper'

describe "cms_page_search", type: :feature, dbscope: :example, js: true do
  let(:site) { cms_site }
  let(:index_path) { cms_page_searches_path site.id }

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
        click_on I18n.t('ss.links.new')

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[search_name]", with: "A"
          click_on I18n.t('ss.buttons.save')
        end

        click_on I18n.t('ss.buttons.search')

        expect(page).to have_css(".search-count", text: "1 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
      end
    end

    context "with filename" do
      it do
        visit index_path
        click_on I18n.t('ss.links.new')

        within "form#item-form" do
          fill_in "item[name]", with: name
          fill_in "item[search_filename]", with: "base/"
          click_on I18n.t('ss.buttons.save')
        end

        click_on I18n.t('ss.buttons.search')

        expect(page).to have_css(".search-count", text: "3 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")
      end
    end

    context "destroy_all_pages" do
      it do
        visit index_path
        click_on I18n.t('ss.links.new')

        within "form#item-form" do
          fill_in "item[name]", with: name
          click_on I18n.t('ss.buttons.save')
        end

        click_on I18n.t('ss.buttons.search')

        expect(page).to have_css(".search-count", text: "4 件の検索結果")
        expect(page).to have_css("div.info a.title", text: "[TEST]A")
        expect(page).to have_css("div.info a.title", text: "[TEST]B")
        expect(page).to have_css("div.info a.title", text: "[TEST]C")
        expect(page).to have_css("div.info a.title", text: "[TEST]D")

        wait_for_js_ready
        within ".list-head" do
          wait_event_to_fire("ss:checked-all-list-items") { find('input[type="checkbox"]').set(true) }
          click_button I18n.t('ss.buttons.delete')
        end
        click_button I18n.t('ss.buttons.delete')
        click_on I18n.t('ss.buttons.search')

        expect(page).to have_css(".search-count", text: "0 件の検索結果")
      end
    end
  end
end
