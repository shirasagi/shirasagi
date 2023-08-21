module Facility::Page
  module Search
    extend ActiveSupport::Concern
    include Map::MapHelper

    included do
      before_save :set_map_points
      before_save :set_sidebar_html

      field :map_points, type: Array, default: []
      field :sidebar_html, type: String, default: ""
    end

    def set_map_points
      self.map_points = []
      maps = Facility::Map.site(site).and_public.where(filename: /^#{filename}\//, depth: depth + 1).to_a

      category_ids = categories.map(&:id)
      image_id = categories.map(&:image_id).first
      image_url = SS::File.find(image_id).url rescue nil

      marker_info = render_marker_info(self)
      maps.each do |map|
        map.map_points.each do |point|
          point[:id] = id
          point[:html] = marker_info
          point[:category] = category_ids
          point[:image] = image_url if image_url.present?
          self.map_points << point
        end
      end
    end

    def set_sidebar_html
      self.sidebar_html = render_map_sidebar(self)
    end
  end
end
