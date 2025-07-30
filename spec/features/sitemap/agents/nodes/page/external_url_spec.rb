require 'spec_helper'

describe "sitemap_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:node) { create :sitemap_node_page, cur_site: site, layout: layout }

  context "when external url is set" do
    let(:sitemap_urls) do
      <<~URL
        https://www.yahoo.co.jp/news/ # ニュース
      URL
    end
    let!(:item) { create :sitemap_page, cur_site: site, cur_node: node, layout: layout, sitemap_urls: sitemap_urls }

    it "#index" do
      visit node.full_url

      within ".sitemap-body" do
        expect(page).to have_css("h2", count: 0)
        expect(page).to have_css("h3", count: 0)
        expect(page).to have_css("h4", count: 0)
        expect(page).to have_css("h5", count: 0)
        expect(page).to have_css("*", count: 0)
      end
    end
  end
end
