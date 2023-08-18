class SS::Migration20201204000000
  include SS::Migration::Base

  depends_on "20201110000000"

  def change
    Cms::Site.where(map_api: 'open_street_map').each do |site|
      site.map_api = 'openlayers'
      site.map_api_layer = SS.config.map.layers.find { |layer| layer['source'] == 'OSM' }.try(:[], 'name')
      site.save
    end
  rescue => e
    Rails.logger.warn("#{e.class} (#{e.message}):\n  #{e.backtrace.join("\n  ")}")
  end
end
