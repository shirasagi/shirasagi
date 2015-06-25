module Facility::Addon
  module ImageInfo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :image_alt, type: String
      field :image_comment, type: String
      field :image_thumb_width, type: Integer, default: 120
      field :image_thumb_height, type: Integer, default: 90

      permit_params :image_alt, :image_comment, :image_thumb_width, :image_thumb_height
    end
  end
end
