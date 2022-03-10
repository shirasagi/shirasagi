require 'spec_helper'

describe Map::Addon::Page, type: :model, dbscope: :example do
  let(:site) { cms_site }
  let!(:node) { create :article_node_page, cur_site: site }
  let(:map_point1) do
    {
      "name" => unique_id, "loc" => [ rand(130..140), rand(30..40) ], "text" => "",
      "image" => "/assets/img/googlemaps/marker#{rand(0..9)}.png"
    }
  end
  let!(:page1) do
    create :article_page, cur_site: site, cur_node: node, map_reference_method: "direct", map_points: [ map_point1 ]
  end

  let!(:form) { create :cms_form, cur_site: site, state: 'public', sub_type: 'static' }
  let!(:column_select_page) do
    create(:cms_column_select_page, cur_site: site, cur_form: form, node_ids: [ node.id ], required: "optional")
  end

  let(:map_point2) do
    {
      "name" => unique_id, "loc" => [ rand(130..140), rand(30..40) ], "text" => "",
      "image" => "/assets/img/googlemaps/marker#{rand(0..9)}.png"
    }
  end
  let!(:page2) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form,
      column_values: [
        column_select_page.value_type.new(column: column_select_page, page_id: page1.id)
      ],
      map_reference_method: "page", map_reference_column_name: column_select_page.name,
      map_points: [ map_point2 ]
    )
  end
  let!(:page3) do
    create(
      :article_page, cur_site: site, cur_node: node, form: form,
      column_values: [
        column_select_page.value_type.new(column: column_select_page, page_id: page2.id)
      ],
      map_reference_method: "page", map_reference_column_name: column_select_page.name
    )
  end

  before do
    node.st_form_ids = [ form.id ]
    node.save!
  end

  describe '#map_reference_method' do
    it do
      # map_reference_method is 'direct'
      map_points, map_options = page1.effective_map_points_and_options
      expect(map_points).to have(1).items
      expect(map_points[0]).to eq map_point1
      expect(map_options).to eq({})

      # map_reference_method is 'page'
      page2.effective_map_points_and_options.tap do |map_points, map_options|
        expect(map_points).to have(1).items
        expect(map_points[0]).to eq map_point1
        expect(map_options).to eq({})
      end

      # page3 refers page2, and page2 refers page1
      page3.effective_map_points_and_options.tap do |map_points, map_options|
        expect(map_points).to have(1).items
        expect(map_points[0]).to eq map_point1
        expect(map_options).to eq({})
      end
    end
  end
end
