require 'spec_helper'

describe "cms_agents_parts_tabs", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout part, cur_site: site }
  let!(:index_page) { create :cms_page, cur_site: site, layout: layout, filename: "index.html" }
  let!(:part) do
    create(:cms_part_tabs, conditions: [node1, node2, node3, node4, node5].map(&:filename))
  end

  let!(:node1) { create :cms_node_page, cur_site: site }
  let!(:node2) { create :cms_node_node, cur_site: site }
  let!(:node3) { create :category_node_page, cur_site: site }
  let!(:node4) { create :category_node_node, cur_site: site }
  let!(:node5) { create :event_node_page, cur_site: site }

  before do
    Capybara.app_host = "http://#{site.domain}"
  end

  context "public" do
    it "#index" do
      visit index_page.url

      within ".cms-tabs" do
        within ".names" do
          expect(page).to have_link node1.name
          expect(page).to have_link node2.name
          expect(page).to have_link node3.name
          expect(page).to have_link node4.name
          expect(page).to have_link node5.name
        end

        # cms_node_page
        within ".names" do
          click_on node1.name
        end
        within "article", visible: true do
          expect(page).to have_css("a[href=\"#{node1.url}\"]", text: I18n.t("ss.links.more"))
          expect(page).to have_css("a[href=\"#{node1.url}rss.xml\"]", text: "RSS")
        end

        # cms_node_node
        within ".names" do
          click_on node2.name
        end
        within "article", visible: true do
          expect(page).to have_css("a[href=\"#{node2.url}\"]", text: I18n.t("ss.links.more"))
          expect(page).to have_no_css("a[href=\"#{node2.url}rss.xml\"]", text: "RSS")
        end

        # category_node_page
        within ".names" do
          click_on node3.name
        end
        within "article", visible: true do
          expect(page).to have_css("a[href=\"#{node3.url}\"]", text: I18n.t("ss.links.more"))
          expect(page).to have_css("a[href=\"#{node3.url}rss.xml\"]", text: "RSS")
        end

        # category_node_node
        within ".names" do
          click_on node4.name
        end
        within "article", visible: true do
          expect(page).to have_css("a[href=\"#{node4.url}\"]", text: I18n.t("ss.links.more"))
          expect(page).to have_no_css("a[href=\"#{node4.url}rss.xml\"]", text: "RSS")
        end

        # event_node_page
        within ".names" do
          click_on node5.name
        end
        within "article", visible: true do
          expect(page).to have_css("a[href=\"#{node5.url}\"]", text: I18n.t("ss.links.more"))
          expect(page).to have_no_css("a[href=\"#{node5.url}rss.xml\"]", text: "RSS")
        end
      end
    end
  end
end
