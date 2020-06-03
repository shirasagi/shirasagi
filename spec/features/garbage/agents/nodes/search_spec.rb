require 'spec_helper'

describe "garbage_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }

  let!(:search_node) do
    create(
      :garbage_node_search,
      filename: "search",
      layout: layout,
      st_category_ids: [category1.id, category2.id, category3.id]
    )
  end
  let!(:page_node) do
    create(
      :garbage_node_node,
      filename: "search/list",
      layout: layout,
      st_category_ids: [category1.id, category2.id, category3.id]
    )
  end

  let!(:category1) { create :garbage_node_category, name: "category1", layout: layout }
  let!(:category2) { create :garbage_node_category, name: "category2", layout: layout }
  let!(:category3) { create :garbage_node_category, name: "category3", layout: layout }

  let!(:item1) do
    create(
      :garbage_node_page,
      name: "item1",
      filename: "search/list/item1",
      layout: layout,
      category_ids: [category1.id],
      remark: "remark1"
    )
  end
  let!(:item2) do
    create(
      :garbage_node_page,
      name: "item2",
      filename: "search/list/item2",
      layout: layout,
      category_ids: [category2.id],
      remark: "remark2"
    )
  end
  let!(:item3) do
    create(
      :garbage_node_page,
      name: "item3",
      filename: "search/list/item3",
      layout: layout,
      category_ids: [category3.id],
      remark: "remark3"
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit search_node.url

      click_on I18n.t("garbage.submit.search")

      expect(page).to have_css(".result .number", text: 3)

      expect(page).to have_css("table.columns td a", text: item1.name)
      expect(page).to have_css("table.columns td", text: category1.name)
      expect(page).to have_css("table.columns td", text: item1.remark)

      expect(page).to have_css("table.columns td a", text: item2.name)
      expect(page).to have_css("table.columns td", text: category2.name)
      expect(page).to have_css("table.columns td", text: item2.remark)

      expect(page).to have_css("table.columns td a", text: item3.name)
      expect(page).to have_css("table.columns td", text: category3.name)
      expect(page).to have_css("table.columns td", text: item3.remark)
    end

    it "#index search with keyword" do
      visit search_node.url

      within 'form' do
        fill_in "name", with: item1.name
      end
      click_on I18n.t("garbage.submit.search")

      expect(page).to have_css(".result .number", text: 1)

      expect(page).to have_css("table.columns td a", text: item1.name)
      expect(page).to have_css("table.columns td", text: category1.name)
      expect(page).to have_css("table.columns td", text: item1.remark)

      expect(page).to have_no_css("table.columns td a", text: item2.name)
      expect(page).to have_no_css("table.columns td", text: category2.name)
      expect(page).to have_no_css("table.columns td", text: item2.remark)

      expect(page).to have_no_css("table.columns td a", text: item3.name)
      expect(page).to have_no_css("table.columns td", text: category3.name)
      expect(page).to have_no_css("table.columns td", text: item3.remark)
    end

    it "#index search with category" do
      visit search_node.url

      within 'form' do
        select category1.name, from: "category_ids[]"
      end
      click_on I18n.t("garbage.submit.search")

      expect(page).to have_css(".result .number", text: 1)

      expect(page).to have_css("table.columns td a", text: item1.name)
      expect(page).to have_css("table.columns td", text: category1.name)
      expect(page).to have_css("table.columns td", text: item1.remark)

      expect(page).to have_no_css("table.columns td a", text: item2.name)
      expect(page).to have_no_css("table.columns td", text: category2.name)
      expect(page).to have_no_css("table.columns td", text: item2.remark)

      expect(page).to have_no_css("table.columns td a", text: item3.name)
      expect(page).to have_no_css("table.columns td", text: category3.name)
      expect(page).to have_no_css("table.columns td", text: item3.remark)
    end
  end
end
