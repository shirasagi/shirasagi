module Cms::Addon
  module Line::Service::ImageMap
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      # https://developers.line.biz/ja/reference/messaging-api/#imagemap-message
      field :area_size, type: Integer
      field :alt_text, type: String
      field :width, type: Integer
      field :height, type: Integer
      belongs_to_file :image1040, class_name: "Cms::Line::File"
      belongs_to_file :image700, class_name: "Cms::Line::File"
      belongs_to_file :image460, class_name: "Cms::Line::File"
      belongs_to_file :image300, class_name: "Cms::Line::File"
      belongs_to_file :image240, class_name: "Cms::Line::File"
      permit_params :area_size, :alt_text, :width, :height
      validate :validate_image
      validates :area_size, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 20 }
      validates :alt_text, presence: true, length: { maximum: 400 }
    end

    def image
      image1040
    end

    def base_url
      return @_base_url if @_base_url.present?
      node = Cms::Node::LineHub.site(site).first
      return unless node
      return unless node.public?
      @_base_url = ::File.join(node.full_url, "image-map", id)
    end

    def image_map_object
      {
        "type": "imagemap",
        "baseUrl": base_url,
        "altText": alt_text,
        "baseSize": {
          "width": width,
          "height": height
        },
        "actions":  areas.map { |area| area.image_map_object }
      }
    end

    private

    def validate_image
      if image1040.blank? && in_image1040.blank?
        errors.add :image1040_id, :blank
      end
      if image700.blank? && in_image700.blank?
        errors.add :image700_id, :blank
      end
      if image460.blank? && in_image460.blank?
        errors.add :image460_id, :blank
      end
      if image300.blank? && in_image300.blank?
        errors.add :image300_id, :blank
      end
      if image240.blank? && in_image240.blank?
        errors.add :image240_id, :blank
      end
    end
  end
end
