module Facility::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana, type: String
      field :address, type: String
      field :tel, type: String
      field :fax, type: String
      field :related_url, type: String

      permit_params :kana, :address, :tel, :fax, :related_url
    end

    set_order 200
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

  module Image
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      belongs_to :image, class_name: "Facility::TempFile"

      permit_params :image_id
    end
  end

  module PointerImage
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      belongs_to :image, class_name: "Facility::TempFile"

      permit_params :image_id
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
