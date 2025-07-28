require 'spec_helper'

describe "sitemap_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :sitemap_node_page, cur_site: site, layout: layout }
  let(:item) { create :sitemap_page, cur_site: site, cur_node: node, layout: layout, sitemap_page_state: "show" }

  before do
    Capybara.app_host = "http://#{site.domain}"

    @disable_redirect_link = SS.config.cms.disable_redirect_link
    SS.config.replace_value_at(:cms, :disable_redirect_link, false)
  end

  after do
    SS.config.replace_value_at(:cms, :disable_redirect_link, @disable_redirect_link)
  end

  context "article node and page" do
    let!(:article_node) { create :article_node_page, cur_site: site, layout: layout }
    let!(:article_page) { create :article_page, cur_site: site, cur_node: article_node, layout: layout }

    let(:node_cls1) { "page--#{article_node.basename}" }
    let(:node_cls2) { "node--#{article_node.basename}" }
    let(:page_cls) { "page--#{article_node.basename}-#{article_page.basename.delete_suffix(".html")}" }

    it "#index" do
      item
      visit node.url
      wait_for_js_ready

      within ".sitemap-body" do
        within "h2.#{node_cls1}" do
          expect(page).to have_selector("a[href=\"#{article_node.url}\"]", text: article_node.name)
        end
        within "h3.#{page_cls}" do
          expect(page).to have_selector("a[href=\"#{article_page.url}\"]", text: article_page.name)
        end
      end
    end
  end

  context "cms node and redirect page" do
    let!(:cms_node) { create :cms_node_page, cur_site: site, layout: layout }
    let!(:cms_page1) { create :cms_page, cur_site: site, cur_node: cms_node, layout: layout }
    let!(:cms_page2) { create :cms_page, cur_site: site, cur_node: cms_node, layout: layout, redirect_link: redirect_link }
    let(:redirect_link) { "https://sample.example.jp" }

    let(:node_cls1) { "page--#{cms_node.basename}" }
    let(:node_cls2) { "node--#{cms_node.basename}" }
    let(:page1_cls) { "page--#{cms_node.basename}-#{cms_page1.basename.delete_suffix(".html")}" }
    let(:page2_cls) { "page--#{cms_node.basename}-#{cms_page2.basename.delete_suffix(".html")}" }

    it "#index" do
      item
      visit node.url
      wait_for_js_ready

      within ".sitemap-body" do
        within "h2.#{node_cls1}" do
          expect(page).to have_selector("a[href=\"#{cms_node.url}\"]", text: cms_node.name)
        end
        within "h3.#{page1_cls}" do
          expect(page).to have_selector("a[href=\"#{cms_page1.url}\"]", text: cms_page1.name)
        end
        within "h3.#{page2_cls}" do
          expect(page).to have_selector("a[href=\"#{redirect_link}\"]", text: cms_page2.name)
        end
      end
    end
  end

  context "rss node and rss page" do
    let!(:rss_node) { create :rss_node_page, cur_site: site, layout: layout }
    let!(:rss_page) { create :rss_page, cur_site: site, cur_node: rss_node, layout: layout }

    let(:node_cls1) { "page--#{rss_node.basename}" }
    let(:node_cls2) { "node--#{rss_node.basename}" }
    let(:page_cls) { "page--#{rss_node.basename}-#{rss_page.basename.delete_suffix(".html")}" }

    it "#index" do
      item
      visit node.url
      wait_for_js_ready

      within ".sitemap-body" do
        within "h2.#{node_cls1}" do
          expect(page).to have_selector("a[href=\"#{rss_node.url}\"]", text: rss_node.name)
        end
        within "h3.#{page_cls}" do
          expect(page).to have_selector("a[href=\"#{rss_page.rss_link}\"]", text: rss_page.name)
        end
      end
    end
  end
end
