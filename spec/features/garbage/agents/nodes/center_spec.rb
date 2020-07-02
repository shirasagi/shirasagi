require 'spec_helper'

describe "garbage_agents_nodes_center", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let!(:center_node) do
    create(
      :garbage_node_center_list,
      filename: "center_list",
      layout: layout
    )
  end
  let!(:item1) do
    create(
      :garbage_node_center,
      name: "center1",
      filename: "center1",
      rest_start: "2020/1/1",
      rest_end: "2020/1/4",
      layout: layout,
      cur_node: center_node
    )
  end
  let!(:item2) do
    create(
      :garbage_node_center,
      name: "center2",
      filename: "center2",
      rest_start: "2020/2/1",
      rest_end: "2020/2/4",
      layout: layout,
      cur_node: center_node
    )
  end
  let!(:item3) do
    create(
      :garbage_node_center,
      name: "center3",
      filename: "center3",
      rest_start: "2020/3/1",
      rest_end: "2020/3/4",
      layout: layout,
      cur_node: center_node
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item1.url
      expect(page).to have_css("table.columns td", text: item1.name)
      expect(page).to have_css("table.columns td", text: item1.rest_start)
      expect(page).to have_css("table.columns td", text: item1.rest_end)

      visit item2.url
      expect(page).to have_css("table.columns td", text: item2.name)
      expect(page).to have_css("table.columns td", text: item2.rest_start)
      expect(page).to have_css("table.columns td", text: item2.rest_end)

      visit item3.url
      expect(page).to have_css("table.columns td", text: item3.name)
      expect(page).to have_css("table.columns td", text: item3.rest_start)
      expect(page).to have_css("table.columns td", text: item3.rest_end)
    end
  end

  context "loop_html" do
    let!(:loop_html) { '<h2><a href="#{url}">#{index_name}</a></h2>#{child_items}' }
    let!(:center_node) do
      create(
        :garbage_node_center_list,
        filename: "center_list",
        layout: layout,
        upper_html: "upper_html",
        lower_html: "lower_html",
        loop_html: loop_html
      )
    end

    it do
      visit center_node.url
      expect(page).to have_content(center_node.upper_html)
      expect(page).to have_css("h2", text: item1.name)
      expect(page).to have_css("h2", text: item2.name)
      expect(page).to have_css("h2", text: item3.name)
      expect(page).to have_content(center_node.lower_html)
    end
  end

  context "liquid" do
    let!(:loop_html) { '<h2><a href="#{url}">#{index_name}</a></h2>#{child_items}' }
    let!(:center_node) do
      create(
        :garbage_node_center_list,
        filename: "center_list",
        layout: layout,
        loop_format: "liquid",
        loop_html: loop_html
      )
    end

    it do
      visit center_node.url
      expect(page).to have_css("h2 a", text: item1.name)
      expect(page).to have_css("h2 a", text: item2.name)
      expect(page).to have_css("h2 a", text: item3.name)
    end
  end
end
