require 'spec_helper'

describe "garbage_agents_nodes_center", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }

  let!(:item1) do
    create(
      :garbage_node_center,
      name: "center1",
      filename: "center1",
      rest_start: "2020/1/1",
      rest_end: "2020/1/4",
      layout: layout
    )
  end

  let!(:item2) do
    create(
      :garbage_node_center,
      name: "center2",
      filename: "center2",
      rest_start: "2020/2/1",
      rest_end: "2020/2/4",
      layout: layout
    )
  end

  let!(:item3) do
    create(
      :garbage_node_center,
      name: "center3",
      filename: "center3",
      rest_start: "2020/3/1",
      rest_end: "2020/3/4",
      layout: layout
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
end
