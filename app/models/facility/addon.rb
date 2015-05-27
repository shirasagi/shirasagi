module Facility::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana, type: String
      field :postcode, type: String
      field :address, type: String
      field :tel, type: String
      field :fax, type: String
      field :related_url, type: String

      permit_params :kana, :postcode, :address, :tel, :fax, :related_url
    end

    set_order 200
  end

  module SearchSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    set_order 200

    included do
      field :search_html, type: String

      permit_params :search_html
    end

    public
      def sort_hash
        return { filename: 1 } if sort.blank?
        { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
      end
  end

  module SearchResult
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 210

    included do
      field :upper_html, type: String, overwrite: true
      field :map_html, type: String

      permit_params :upper_html, :map_html
    end
  end

  module AdditionalInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :additional_info, type: Facility::Extensions::AdditionalInfo

      permit_params additional_info: [ :field, :value ]
    end

    set_order 210
  end

  module FocusSetting
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      field :center_point, type: ::Map::Extensions::Point

      permit_params center_point: [ :loc, :zoom_level ]
    end
  end

  module Image
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      belongs_to :image, class_name: "SS::File"
      permit_params :image_id

      before_save :save_image
      after_destroy :destroy_image
    end

    def save_image
      return true unless image_id_changed?
      image.update_attribute(:site_id, site_id)
      image.update_attribute(:model, "facility/file")

      if image_id_was
        file = SS::File.where(id: image_id_was).first
        file.destroy if file
      end
    end

    def destroy_image
      image.destroy if image
    end
  end

  module ImageInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 210

    included do
      field :image_alt, type: String
      field :image_comment, type: String
      field :image_thumb_width, type: Integer, default: 120
      field :image_thumb_height, type: Integer, default: 90

      permit_params :image_alt, :image_comment, :image_thumb_width, :image_thumb_height
    end
  end
end
