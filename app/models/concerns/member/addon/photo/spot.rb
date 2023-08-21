module Member::Addon::Photo
  module Spot
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :member_photos, class_name: "Member::Photo"
      permit_params member_photo_ids: []

      liquidize do
        export as: :member_photos do
          member_photos.and_public.order_by(order: 1, released: -1)
        end
      end
    end
  end
end
