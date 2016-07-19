module Facility::Addon::Image
  module Model
    extend ActiveSupport::Concern
    extend SS::Translation

    included do
      belongs_to :image, class_name: "SS::File"
      permit_params :image_id

      before_save :save_image
      after_destroy :destroy_image
    end

    def save_image
      image.update_attributes(site_id: site_id, model: "facility/file", state: state) if image

      if image_id_changed? && image_id_was
        file = SS::File.where(id: image_id_was).first
        file.destroy if file
      end
    end

    def destroy_image
      image.destroy if image
    end
  end
end
