require 'spec_helper'

describe "garbage_agents_nodes_remark", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }

  let!(:item1) do
    create(
      :garbage_node_remark,
      name: "remark1",
      filename: "remark1",
      remark_id: 1,
      attention: "attention1",
      layout: layout
    )
  end

  let!(:item2) do
    create(
      :garbage_node_remark,
      name: "remark2",
      filename: "remark2",
      remark_id: 2,
      attention: "attention2",
      layout: layout
    )
  end

  let!(:item3) do
    create(
      :garbage_node_remark,
      name: "remark3",
      filename: "remark3",
      remark_id: 3,
      attention: "attention3",
      layout: layout
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
end
