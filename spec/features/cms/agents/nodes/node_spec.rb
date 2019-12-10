require 'spec_helper'

describe "cms_agents_nodes_node", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :cms_node_node, layout_id: layout.id, filename: "node" }

  context "public" do
    let!(:item) { create :cms_node, filename: "node/item" }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
    end

    it "#kana", mecab: true do
      visit node.url.sub('/', SS.config.kana.location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector("article")
      expect(page).to have_selector("a[href='/node/item/']")
    end

    it "#mobile" do
      visit node.url.sub('/', site.mobile_location + '/')
      expect(status_code).to eq 200
      expect(page).to have_css(".nodes")
      expect(page).to have_selector(".tag-article")
      expect(page).to have_selector("a[href='/mobile/node/item/']")
    end
  end

  context "public with child_item conditions" do
    let (:upper_html) { '<div>' }
    let (:loop_html) { '<h2><a href="#{url}">#{index_name}</a></h2>#{child_items}' }
    let (:lower_html) { '</div>' }
    let (:child_upper_html) { '<ul>' }
    let (:child_loop_html) { '<li>#{index_name}</li>' }
    let (:child_lower_html) { '</ul>' }
    let(:cms_node) do
      create :cms_node_node, layout_id: layout.id, filename: "cms-node",
             upper_html: upper_html, loop_html: loop_html, lower_html: lower_html,
             child_upper_html: child_upper_html, child_loop_html: child_loop_html, child_lower_html: child_lower_html
    end
    let!(:pages) { create :cms_node_page, layout_id: layout.id, filename: "cms-node/pages", sort: 'order' }
    let!(:docs_node) { create :cms_node_node, layout_id: layout.id, filename: "cms-node/pages/node", order: 20 }

    let!(:item_1) { create :cms_page, filename: "cms-node/pages/item_1.html", group_ids: [cms_group.id], order: 10 }
    let!(:item_2) { create :article_page, filename: "cms-node/pages/item_2.html", group_ids: [cms_group.id], order: 30 }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit cms_node.url
      expect(status_code).to eq 200
      expect(page).to have_link(pages.name)
      expect(page.body.include?("<li>#{item_1.name}</li><li>#{docs_node.name}</li><li>#{item_2.name}</li>")).to be_truthy
    end
  end
end
