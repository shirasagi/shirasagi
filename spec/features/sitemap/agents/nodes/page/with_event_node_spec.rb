require 'spec_helper'

describe "sitemap_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout cur_site: site }
  let!(:sitemap_node) { create :sitemap_node_page, cur_site: site, layout: layout }
  let!(:event_node) { create :event_node_page, cur_site: site, layout: layout }
  let!(:event_page) { create :event_page, cur_site: site, layout: layout }

  context "when external url is set" do
    let(:next_month) { Time.zone.now.beginning_of_month + 1.month }
    let(:path) { "#{event_node.filename}/#{next_month.strftime("%Y%m")}" }
    let(:title) { "イベントカレンダー 表形式 #{next_month.strftime("%Y年%1m月")}" }
    let(:sitemap_urls) do
      <<~URL
        /#{path}/ # #{title}
      URL
    end
    let!(:sitemap_page) { create :sitemap_page, cur_site: site, cur_node: sitemap_node, layout: layout, sitemap_urls: sitemap_urls }

    it "#index" do
      visit sitemap_node.full_url

      within ".sitemap-body" do
        within "h2.page--#{path.tr("/", "-")}" do
          expect(page).to have_css("*", count: 1)
          expect(page).to have_link(title, href: "/#{path}/")
        end
      end
    end
  end
end
