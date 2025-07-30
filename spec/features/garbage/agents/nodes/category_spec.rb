require 'spec_helper'

describe "garbage_agents_nodes_category", type: :feature, dbscope: :example, js: true do
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
  let!(:category1) { create :garbage_node_category, layout: layout }
  let!(:category2) { create :garbage_node_category, layout: layout }
  let!(:category3) { create :garbage_node_category, layout: layout }
  let!(:item1) do
    create(
      :garbage_node_page,
      name: "item1",
      filename: "search/list/item1",
      layout: layout,
      category_ids: [category1.id],
      kana: "kana1",
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
      kana: "kana2",
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
      kana: "kana3",
      remark: "remark3"
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit category1.url

      expect(page).to have_css("table.columns td a", text: item1.name)
      expect(page).to have_css("table.columns td", text: category1.name)
      expect(page).to have_css("table.columns td", text: item1.kana)
      expect(page).to have_css("table.columns td", text: item1.remark)

      expect(page).to have_no_css("table.columns td a", text: item2.name)
      expect(page).to have_no_css("table.columns td", text: category2.name)
      expect(page).to have_no_css("table.columns td", text: item2.kana)
      expect(page).to have_no_css("table.columns td", text: item2.remark)

      expect(page).to have_no_css("table.columns td a", text: item3.name)
      expect(page).to have_no_css("table.columns td", text: category3.name)
      expect(page).to have_no_css("table.columns td", text: item3.kana)
      expect(page).to have_no_css("table.columns td", text: item3.remark)

      visit category2.url

      expect(page).to have_no_css("table.columns td a", text: item1.name)
      expect(page).to have_no_css("table.columns td", text: category1.name)
      expect(page).to have_no_css("table.columns td", text: item1.kana)
      expect(page).to have_no_css("table.columns td", text: item1.remark)

      expect(page).to have_css("table.columns td a", text: item2.name)
      expect(page).to have_css("table.columns td", text: category2.name)
      expect(page).to have_css("table.columns td", text: item2.kana)
      expect(page).to have_css("table.columns td", text: item2.remark)

      expect(page).to have_no_css("table.columns td a", text: item3.name)
      expect(page).to have_no_css("table.columns td", text: category3.name)
      expect(page).to have_no_css("table.columns td", text: item3.kana)
      expect(page).to have_no_css("table.columns td", text: item3.remark)

      visit category3.url

      expect(page).to have_no_css("table.columns td a", text: item1.name)
      expect(page).to have_no_css("table.columns td", text: category1.name)
      expect(page).to have_no_css("table.columns td", text: item1.kana)
      expect(page).to have_no_css("table.columns td", text: item1.remark)

      expect(page).to have_no_css("table.columns td a", text: item2.name)
      expect(page).to have_no_css("table.columns td", text: category2.name)
      expect(page).to have_no_css("table.columns td", text: item2.kana)
      expect(page).to have_no_css("table.columns td", text: item2.remark)

      expect(page).to have_css("table.columns td a", text: item3.name)
      expect(page).to have_css("table.columns td", text: category3.name)
      expect(page).to have_css("table.columns td", text: item3.kana)
      expect(page).to have_css("table.columns td", text: item3.remark)
    end
  end


  context "loop_html" do
    let!(:loop_html) { '<h2><a href="#{url}">#{index_name}</a></h2>#{child_items}' }
    let!(:page_node) do
      create(
        :garbage_node_node,
        filename: "search/list",
        layout: layout,
        st_category_ids: [category1.id, category2.id, category3.id],
        upper_html: "upper_html",
        lower_html: "lower_html",
        loop_html: loop_html
      )
    end

    it do
      visit page_node.url
      expect(page).to have_content(page_node.upper_html)
      expect(page).to have_css("h2", text: item1.name)
      expect(page).to have_css("h2", text: item2.name)
      expect(page).to have_css("h2", text: item3.name)
      expect(page).to have_content(page_node.lower_html)
    end
  end

  context "liquid" do
    let!(:loop_html) { '<h2><a href="#{url}">#{index_name}</a></h2>#{child_items}' }
    let!(:page_node) do
      create(
        :garbage_node_node,
        filename: "search/list",
        layout: layout,
        st_category_ids: [category1.id, category2.id, category3.id],
        loop_html: loop_html
      )
    end

    it do
      visit page_node.url
      expect(page).to have_css("h2", text: item1.name)
      expect(page).to have_css("h2", text: item2.name)
      expect(page).to have_css("h2", text: item3.name)
    end
  end
end
