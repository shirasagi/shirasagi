require 'spec_helper'

describe "facility_agents_nodes_page", type: :feature, dbscope: :example do
  let(:site)   { cms_site }
  let(:layout) { create_cms_layout }
  let(:node)   { create :facility_node_node, layout_id: layout.id, filename: "node" }
  let(:item) do
    create(:facility_node_page, filename: "node/item", cur_node: node,
           kana: "kana", postcode: "postcode", address: "address", tel: "tel",
           fax: "fax", related_url: "related_url", additional_info: [{:field=>"additional_info", :value=>"additional_info"}])
  end
  let!(:map) do
    create :facility_map, filename: "node/item/#{unique_id}",
           map_points: [{"name" => item.name, "loc" => [34.067035, 134.589971], "text" => unique_id}]
  end
  let!(:file) {create :ss_file}
  let!(:image) do
    create :facility_image, filename: "node/item/#{unique_id}", image_id: file.id
  end
  let(:event_node) { create :event_node_page, layout_id: layout.id }
  let!(:event) { create :event_page, event_dates: [Time.zone.today], facility_ids: [item.id], cur_node: event_node }

  context "public" do
    before do
      Capybara.app_host = "http://#{site.domain}"
    end

    it "#index" do
      visit item.url
      expect(page).to have_selector("a[href='/#{image.filename}']")
      expect(page).to have_content "kana"
      expect(page).to have_content "postcode"
      expect(page).to have_content "address"
      expect(page).to have_content "tel"
      expect(page).to have_content "fax"
      expect(page).to have_selector("a[href='related_url']")
      expect(page).to have_content "additional_info"
      expect(page).to have_content event.name
      expect(page).to have_selector('#map-canvas')
    end
  end
end
