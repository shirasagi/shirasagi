class SS::Migration20210625000000
  include SS::Migration::Base

  depends_on "20210622000000"

  def change
    ids = Cms::Page.pluck(:id)
    ids.each do |id|
      item = Cms::Page.find(id) rescue nil
      next unless item
      next unless item.respond_to?(:map_points)
      next unless item.map_points.present?

      map_points = item.map_points.map do |map_point|
        if map_point["loc"].present?
          lat = map_point["loc"][0]
          lon = map_point["loc"][1]
          map_point["loc"] = [lon, lat] if lat < lon
        end
        map_point
      end
      item.set(map_points: map_points)
    end
  end
end
