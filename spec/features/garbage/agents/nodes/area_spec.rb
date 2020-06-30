require 'spec_helper'

describe "garbage_agents_nodes_area_lists", type: :feature, dbscope: :example, js: true do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:edit_path) { edit_garbage_area_path site.id, area_node, item }

  let!(:search_node) do
    create(
      :garbage_node_search,
      filename: "search",
      layout: layout,
      st_category_ids: [category.id]
    )
  end
  let!(:area_node) do
    create(
      :garbage_node_area_list,
      filename: "search/list",
      layout: layout,
      st_category_ids: [category.id]
    )
  end

  let!(:category) { create :garbage_node_category, name: "category", layout: layout }


  let!(:item) do
    create(
      :garbage_node_area,
      name: "item",
      filename: "search/list/item",
      layout: layout
    )
  end

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end
    before { login_cms_user }

    it "#index" do
      visit edit_path
      select category.name, from: "item_garbage_type__field"
      fill_in "item[garbage_type][][value]", with: "月"
      fill_in "item[garbage_type][][view]", with: "毎週月曜日"
      click_button I18n.t('ss.buttons.save')
      item.reload

      visit item.url
      expect(page).to have_css("table.columns td", text: item.garbage_type.first[:filed])
      expect(page).to have_css("table.columns td", text: item.garbage_type.first[:view])
    end
  end
end
