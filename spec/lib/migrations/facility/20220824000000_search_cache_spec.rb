require 'spec_helper'
require Rails.root.join("lib/migrations/facility/20220824000000_search_cache.rb")

RSpec.describe SS::Migration20220824000000, dbscope: :example do
  let!(:node) { create :facility_node_search, filename: "node" }
  let!(:item1) { create :facility_node_page, filename: "node/item1" }
  let!(:item2) { create :facility_node_page, filename: "node/item2" }
  let!(:item3) { create :facility_node_page, filename: "node/item3" }

  let!(:loc) { [134.589971, 34.067035] }
  let!(:map_point1) { {"name" => item1.name, "loc" => loc, "text" => unique_id} }
  let!(:map_point2) { {"name" => item2.name, "loc" => loc, "text" => unique_id} }
  let!(:map_point3) { {"name" => item3.name, "loc" => loc, "text" => unique_id} }

  let!(:map1) { create :facility_map, cur_node: item1, map_points: [map_point1] }
  let!(:map2) { create :facility_map, cur_node: item2, map_points: [map_point2] }
  let!(:map3) { create :facility_map, cur_node: item3, map_points: [map_point3] }

  def first_point(map_points)
    h = map_points[0]
    return nil unless h
    h.slice("name", "loc", "text")
  end

  it do
    expect(first_point(item1.map_points)).to eq map_point1
    expect(first_point(item2.map_points)).to eq map_point2
    expect(first_point(item3.map_points)).to eq map_point3

    item1.unset(:map_points)
    item2.unset(:map_points)
    item3.unset(:map_points)

    item1.reload
    item2.reload
    item3.reload

    expect(first_point(item1.map_points)).to eq nil
    expect(first_point(item2.map_points)).to eq nil
    expect(first_point(item3.map_points)).to eq nil

    require 'rake'
    Rails.application.load_tasks
    described_class.new.change

    item1.reload
    item2.reload
    item3.reload

    expect(first_point(item1.map_points)).to eq map_point1
    expect(first_point(item2.map_points)).to eq map_point2
    expect(first_point(item3.map_points)).to eq map_point3
  end
end
