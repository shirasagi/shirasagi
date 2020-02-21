module Member::Addon::Photo
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      belongs_to_file :image, class_name: "Member::PhotoFile", required: true
      field :caption, type: String, metadata: { unicode: :nfc }

      permit_params :caption, :image_id, :loc

      validate :validate_in_image

      after_save :update_relation_image_member

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
        template_variable_handler('thumb.src', :template_variable_handler_thumb_src)
      end

      liquidize do
        export as: :image do
          image ? SS::File.find(image.id) : nil
        end
      end
    end

    private

    def template_variable_handler_img_src(name, issuer)
      image.try(:url)
    end

    def template_variable_handler_thumb_src(name, issuer)
      image.try(:thumb_url) || "/assets/img/dummy.png"
    end

    def validate_in_image
      return unless in_image
      begin
        ext = ::File.extname(in_image.original_filename)
        raise ext if ext !~ /\.(bmp|gif|jpe?g|png)$/i
        Magick::Image.from_blob(in_image.read).shift
        in_image.rewind
      rescue
        errors.add :image_id, :invalid_file_type
      end
    end

    def update_relation_image_member
      return unless member
      image.member_id = member.id
      image.update
    end
  end
end
