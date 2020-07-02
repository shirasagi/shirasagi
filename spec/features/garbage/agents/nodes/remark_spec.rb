require 'spec_helper'

describe "garbage_agents_nodes_remark", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let!(:remark_node) do
    create(
      :garbage_node_remark_list,
      filename: "remark_list",
      layout: layout
    )
  end
  let!(:item1) do
    create(
      :garbage_node_remark,
      name: "remark1",
      filename: "remark1",
      remark_id: 1,
      attention: "attention1",
      layout: layout,
      cur_node: remark_node
    )
  end
  let!(:item2) do
    create(
      :garbage_node_remark,
      name: "remark2",
      filename: "remark2",
      remark_id: 2,
      attention: "attention2",
      layout: layout,
      cur_node: remark_node
    )
  end
  let!(:item3) do
    create(
      :garbage_node_remark,
      name: "remark3",
      filename: "remark3",
      remark_id: 3,
      attention: "attention3",
      layout: layout,
      cur_node: remark_node
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item1.url

      expect(page).to have_css("table.columns td", text: item1.remark_id)
      expect(page).to have_css("table.columns td", text: item1.attention)

      visit item2.url
      expect(page).to have_css("table.columns td", text: item2.remark_id)
      expect(page).to have_css("table.columns td", text: item2.attention)

      visit item3.url
      expect(page).to have_css("table.columns td", text: item3.remark_id)
      expect(page).to have_css("table.columns td", text: item3.attention)
    end
  end

  context "loop_html" do
    let!(:loop_html) { '<div class="#{class}"><header><h2>#{name}</h2></header></div>' }
    let!(:remark_node) do
      create(
        :garbage_node_remark_list,
        filename: "remark_list",
        layout: layout,
        upper_html: "upper_html",
        lower_html: "lower_html",
        loop_html: loop_html
      )
    end

    it do
      visit remark_node.url
      expect(page).to have_content(remark_node.upper_html)
      expect(page).to have_css("h2", text: item1.name)
      expect(page).to have_css("h2", text: item2.name)
      expect(page).to have_css("h2", text: item3.name)
      expect(page).to have_content(remark_node.lower_html)
    end
  end

  context "liquid" do
    let!(:loop_html) { '<div class="#{class}"><header><h2>#{name}</h2></header></div>' }
    let!(:remark_node) do
      create(
        :garbage_node_remark_list,
        filename: "remark_list",
        layout: layout,
        loop_format: "liquid",
        loop_html: loop_html
      )
    end

    it do
      visit remark_node.url
      expect(page).to have_css("h2 a", text: item1.name)
      expect(page).to have_css("h2 a", text: item2.name)
      expect(page).to have_css("h2 a", text: item3.name)
    end
  end
end
