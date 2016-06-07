module Member::Addon::Photo
  module Photo
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      embeds_ids :member_photos, class_name: "Member::Photo"
      permit_params member_photo_ids: []
    end
  end
end
