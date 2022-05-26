class Map::Agents::Parts::GeolocationPageController < ApplicationController
  include Cms::PartFilter::View
  helper Cms::ListHelper

  def index
    @items = []
    return if @cur_page.nil?
    return if @cur_page.map_points.blank?

    loc = @cur_page.map_points[0]["loc"]
    locations = Map::Geolocation.where(@cur_part.condition_hash).
      where(:owner_item_id.ne => @cur_page.id).
      geonear(loc, @cur_part.limit)
    @items = locations.map(&:item)
  end
end
