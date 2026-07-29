require 'spec_helper'

describe "cms_agents_nodes_page", type: :feature, dbscope: :example, js: true do
  let!(:site) { cms_site }
  let!(:layout) { create_cms_layout }

  context "root index page" do
    let!(:item) do
      html = <<~HTML
        <p class="hello">#{unique_id}</p>
      HTML
      item = create :cms_page, cur_site: site, layout: layout, basename: "index.html", html: html
      FileUtils.rm_rf(item.path)
      item
    end

    it do
      visit item.full_url
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{site.full_url}\"]")
      expect(page).to have_css(".hello")
    end
  end

  context "root non-index page" do
    let!(:item) do
      html = <<~HTML
        <p class="hello">#{unique_id}</p>
      HTML
      item = create :cms_page, cur_site: site, layout: layout, basename: "#{unique_id}.html", html: html
      FileUtils.rm_rf(item.path)
      item
    end

    it do
      visit item.full_url
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{item.full_url}\"]")
      expect(page).to have_css(".hello")
    end
  end

  context "index page under a folder" do
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
    let!(:item) do
      html = <<~HTML
        <p class="hello">#{unique_id}</p>
      HTML
      item = create :cms_page, cur_site: site, cur_node: node, layout: layout, basename: "index.html", html: html
      FileUtils.rm_rf(item.path)
      item
    end

    it do
      visit item.full_url
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{node.full_url}\"]")
      expect(page).to have_css(".hello")
    end
  end

  context "non-index page under a folder" do
    let!(:node) { create :article_node_page, cur_site: site, layout: layout }
    let!(:item) do
      html = <<~HTML
        <p class="hello">#{unique_id}</p>
      HTML
      item = create :cms_page, cur_site: site, cur_node: node, layout: layout, basename: "#{unique_id}.html", html: html
      FileUtils.rm_rf(item.path)
      item
    end

    it do
      visit item.full_url
      expect(page).to have_css("[rel=\"canonical\"][href=\"#{item.full_url}\"]")
      expect(page).to have_css(".hello")
    end
  end
end
