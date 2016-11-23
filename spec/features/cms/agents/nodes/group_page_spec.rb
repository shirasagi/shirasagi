require 'spec_helper'

describe "cms_agents_nodes_group_page", type: :feature, dbscope: :example do
  let(:site) { cms_site }
  let(:layout) { create_cms_layout }

  context "public" do
    let!(:node) { create :cms_node_group_page, layout_id: layout.id, filename: "node", condition_group_ids: [cms_group.id] }
    let!(:item_1) { create :cms_page, filename: "node/item_1.html", group_ids: [cms_group.id] }
    let!(:item_2) { create :article_page, filename: "node/item_2.html", group_ids: [cms_group.id] }
    let!(:item_3) { create :event_page, filename: "node/item_3.html", group_ids: [cms_group.id] }
    let!(:item_4) { create :cms_page, filename: "node/item_4.html", group_ids: [] }
    let!(:item_5) { create :article_page, filename: "node/item_5.html", group_ids: [] }
    let!(:item_6) { create :event_page, filename: "node/item_6.html", group_ids: [] }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".cms-group-pages")
      expect(page).to have_css(".pages")
      expect(page).to have_link(item_1.name)
      expect(page).to have_link(item_2.name)
      expect(page).to have_link(item_3.name)
      expect(page).to have_no_link(item_4.name)
      expect(page).to have_no_link(item_5.name)
      expect(page).to have_no_link(item_6.name)
    end
  end

  context "public with url conditions" do
    let!(:node) do
      create :cms_node_group_page, layout_id: layout.id, filename: "node", condition_group_ids: [cms_group.id], conditions: "docs"
    end
    let!(:docs) { create :article_node_page, layout_id: layout.id, filename: "docs" }
    let!(:faq) { create :faq_node_page, layout_id: layout.id, filename: "faq" }

    let!(:item_1) { create :cms_page, filename: "docs/item_1.html", group_ids: [cms_group.id] }
    let!(:item_2) { create :article_page, filename: "docs/item_2.html", group_ids: [cms_group.id] }
    let!(:item_3) { create :event_page, filename: "docs/item_3.html", group_ids: [cms_group.id] }
    let!(:item_4) { create :cms_page, filename: "faq/item_4.html", group_ids: [cms_group.id] }
    let!(:item_5) { create :article_page, filename: "faq/item_5.html", group_ids: [cms_group.id] }
    let!(:item_6) { create :event_page, filename: "faq/item_6.html", group_ids: [cms_group.id] }

    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit node.url
      expect(status_code).to eq 200
      expect(page).to have_css(".cms-group-pages")
      expect(page).to have_css(".pages")
      expect(page).to have_link(item_1.name)
      expect(page).to have_link(item_2.name)
      expect(page).to have_link(item_3.name)
      expect(page).to have_no_link(item_4.name)
      expect(page).to have_no_link(item_5.name)
      expect(page).to have_no_link(item_6.name)
    end
  end
end
