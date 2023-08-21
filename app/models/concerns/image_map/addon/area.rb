module ImageMap::Addon
  module Area
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      attr_accessor :in_area

      field :shape, type: String, default: "rect"
      field :coords, type: Array, default: []
      field :link_url, type: String
      field :area_state, type: String

      permit_params in_area: [:x, :y, :width, :height]
      permit_params :link_url, :area_state

      validate :validate_in_area
      validate :validate_link_url
      validates :link_url, "sys/trusted_url" => true, if: ->{ Sys::TrustedUrlValidator.url_restricted? }
    end

    def area_anchor
      "area-content-#{id}"
    end

    def parse_in_area
      if in_area
        self.in_area = OpenStruct.new(in_area)
        return
      end

      self.in_area = OpenStruct.new
      return if coords.blank?

      self.in_area.x = coords[0]
      self.in_area.y = coords[1]
      self.in_area.width = (coords[2] - coords[0])
      self.in_area.height = (coords[3] - coords[1])
    end

    def area_state_options
      (cur_node || parent).area_state_options
    rescue
      []
    end

    private

    def validate_link_url
      return if link_url.blank?
      Addressable::URI.parse(link_url)
    rescue
      errors.add :link_url, :invalid
    end

    def validate_in_area
      return if in_area.blank?
      area = OpenStruct.new(in_area.select { |_, v| v.present? }) rescue nil

      if area.nil? || !(area.x && area.y && area.width && area.height)
        errors.add :in_area, :incorrectly
        return
      end

      self.coords = []
      self.coords[0] = area.x.to_i
      self.coords[1] = area.y.to_i
      self.coords[2] = area.x.to_i + area.width.to_i
      self.coords[3] = area.y.to_i + area.height.to_i
    end
  end
end
