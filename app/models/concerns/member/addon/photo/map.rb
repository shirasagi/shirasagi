module Member::Addon::Photo
  module Map
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_points, type: ::Map::Extensions::Points, default: []
      permit_params map_points: [ :name, :loc, :text, :html, :link, :image ]

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
