require 'spec_helper'

describe Map::Addon::Page, dbscope: :example do
  let(:site) { cms_site }

  xcontext "estimate disk usage for points on the map" do
    let!(:item) { create :cms_page, cur_site: site }

    it do
      expect(Cms::Page.where(id: item.id).count).to eq 1
      size = Cms::Page.where(id: item.id).total_bsonsize
      puts "initial size=#{size.to_fs(:delimited)}"

      map_points = []
      100.times do
        map_points << {
          "name" => Array.new(10) { unique_id }.join,
          "loc" => [ 138.047394, 36.233837 ],
          "text" => Array.new(10) { Array.new(10) { unique_id }.join }.join("\r\n"),
          "image" => "/assets/img/openlayers/marker3.png"
        }
      end
      item.map_points = map_points
      item.save!

      item.reload
      expect(item.map_points.length).to eq 100

      size = Cms::Page.where(id: item.id).total_bsonsize
      puts "after 100 points added=#{size.to_fs(:delimited)} (#{size.to_fs(:human_size)})"

      900.times do
        map_points << {
          "name" => Array.new(10) { unique_id }.join,
          "loc" => [ 138.047394, 36.233837 ],
          "text" => Array.new(10) { Array.new(10) { unique_id }.join }.join("\r\n"),
          "image" => "/assets/img/openlayers/marker3.png"
        }
      end
      item.map_points = map_points
      item.save!

      item.reload
      expect(item.map_points.length).to eq 1_000

      size = Cms::Page.where(id: item.id).total_bsonsize
      puts "after 1,000 points added=#{size.to_fs(:delimited)} (#{size.to_fs(:human_size)})"

      1000.times do
        map_points << {
          "name" => Array.new(10) { unique_id }.join,
          "loc" => [ 138.047394, 36.233837 ],
          "text" => Array.new(10) { Array.new(10) { unique_id }.join }.join("\r\n"),
          "image" => "/assets/img/openlayers/marker3.png"
        }
      end
      item.map_points = map_points
      item.save!

      item.reload
      expect(item.map_points.length).to eq 2_000

      size = Cms::Page.where(id: item.id).total_bsonsize
      puts "after 2,000 points added=#{size.to_fs(:delimited)} (#{size.to_fs(:human_size)})"
    end
  end
end
