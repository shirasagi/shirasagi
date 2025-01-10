require 'spec_helper'

describe "facility_agents_nodes_search", type: :feature, dbscope: :example, js: true do
  let!(:layout) { create_cms_layout }
  let!(:facility_node) { create :facility_node_node, layout: layout }
  let!(:facility_page) do
    create(
      :facility_node_page, cur_node: facility_node, layout: layout, address: "address-#{unique_id}", tel: "tel-#{unique_id}"
    )
  end
  let!(:facility_image1) do
    image = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "logo.png")
    create(:facility_image, cur_node: facility_page, image_id: image.id, image_alt: unique_id, order: 10)
  end
  let!(:facility_image2) do
    image = tmp_ss_file(contents: "#{Rails.root}/spec/fixtures/ss/logo.png", basename: "logo.png")
    create(:facility_image, cur_node: facility_page, image_id: image.id, image_alt: unique_id, order: 20)
  end
  let!(:facility_map) do
    create(
      :facility_map, cur_node: facility_page,
      map_points: [{"name" => unique_id, "loc" => [134.589971, 34.067035], "text" => unique_id}]
    )
  end
  let!(:facility_notice) { create(:facility_notice, cur_node: facility_page) }

  it do
    visit facility_node.full_url
    within ".facility-nodes" do
      expect(page).to have_css(".facility-page", text: facility_page.name)
      click_on facility_page.name
    end

    within ".summary-image" do
      "[alt=\"#{facility_image1.image_alt}\"]".tap do |selector|
        expect(page).to have_css(selector)
        image_element_info(first(selector)).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
      end
    end
    within ".images" do
      "[alt=\"#{facility_image2.image_alt}\"]".tap do |selector|
        expect(page).to have_css(selector)
        image_element_info(first(selector)).tap do |info|
          expect(info[:width]).to eq 90
          expect(info[:height]).to eq 90
        end
      end
    end
    expect(page).to have_css(".item-#{::File.basename(facility_notice.filename, ".*")}", text: facility_notice.name)
    expect(page).to have_css("#map-canvas")
  end
end
