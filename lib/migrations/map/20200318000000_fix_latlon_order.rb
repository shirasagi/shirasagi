class SS::Migration20200318000000
  include SS::Migration::Base

  depends_on "20200204000001"

  def change
    ids = Cms::Page.pluck(:id)
    ids.each do |id|
      item = Cms::Page.find(id) rescue nil
      next unless item

      item = item.becomes_with_route
      next unless item.respond_to?(:map_points)
      next unless item.map_points.present?

      map_points = item.map_points.map do |map_point|
        if map_point["loc"].present?
          lat = map_point["loc"][0]
          lon = map_point["loc"][1]
          map_point["loc"] = [lon, lat] if lat < lon
          map_point
        else
          map_point
        end
      end
      item.set(map_points: map_points)
    end
  end
end
