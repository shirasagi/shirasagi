require 'spec_helper'
require Rails.root.join("lib/migrations/map/20200318000000_fix_latlon_order.rb")

RSpec.describe SS::Migration20200318000000, dbscope: :example do
  let(:node)   { create :facility_node_search, layout_id: layout.id, filename: "node" }
  let(:item) { create :facility_node_page, filename: "node/item" }
  let!(:map1) do
    create :facility_map, filename: "node/item/#{unique_id}",
           map_points: [{"name" => item.name, "loc" => [34.067035, 134.589971], "text" => unique_id}]
  end
  let!(:map2) do
    create :facility_map, filename: "node/item/#{unique_id}",
           map_points: [
             {"name" => item.name, "loc" => [34.067035, 134.589971], "text" => unique_id},
             {"name" => item.name, "loc" => [35.067035, 135.589971], "text" => unique_id}
           ]
  end

  it do
    expect(map1.map_points.first["loc"]).to eq [134.589971, 34.067035]
    expect(map2.map_points.first["loc"]).to eq [134.589971, 34.067035]
    expect(map2.map_points.last["loc"]).to eq [135.589971, 35.067035]
  end
end
