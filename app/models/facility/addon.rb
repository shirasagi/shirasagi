module Facility::Addon
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana, type: String
      field :address, type: String
      field :tel, type: String
      field :fax, type: String
      field :homepage, type: String

      permit_params :kana, :address, :tel, :fax, :homepage
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
      belongs_to :image, class_name: "SS::File"

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

      permit_params :image_alt, :image_comment
    end
  end

  module PointerImage
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 200

    included do
      belongs_to :image, class_name: "SS::File"

      permit_params :image_id
    end
  end

end
