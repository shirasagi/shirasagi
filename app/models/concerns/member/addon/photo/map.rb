module Member::Addon::Photo
  module Map
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: ::Map::Extensions::Points, default: []
      field :map_zoom_level, type: Integer
      field :center_setting, type: String, default: "auto"
      field :set_center_position, type: String
      field :zoom_setting, type: String, default: "auto"
      field :set_zoom_level, type: Integer
      permit_params map_points: [ :name, :loc, :text, :html, :link, :image ]
      permit_params :map_zoom_level, :center_setting, :set_center_position, :zoom_setting, :set_zoom_level

      before_save :set_marker_html
    end

    def set_marker_html
      return unless map_points.present?

      h = []
      h << %(<a href="#{url}">)
      h << %(<img class="thumb" src="#{image.thumb_url}" alt="#{name}">)
      h << %(</a>)
      self.map_points = map_points.map do |point|
        point[:name] = name
        point[:html] = h.join
        point
      end
    end
  end
end
