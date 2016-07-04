module Member::Addon::Photo
  module Body
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      belongs_to_file :image, class_name: "Member::PhotoFile"
      field :caption, type: String, metadata: { unicode: :nfc }

      permit_params :caption, :image_id, :loc

      validate :validate_image
      validate :validate_in_image

      after_save :update_relation_image_member

      if respond_to?(:template_variable_handler)
        template_variable_handler('img.src', :template_variable_handler_img_src)
      end
    end

    def template_variable_handler_img_src(name, issuer)
      img_source = ERB::Util.html_escape("/assets/img/dummy.png")

      if image && image.thumb_url.present?
        img_source = ERB::Util.html_escape(image.thumb_url)
      end
      img_source
    end

    def validate_image
      errors.add :image, :empty if !image && !in_image
    end

    def validate_in_image
      return unless in_image
      begin
        ext = ::File.extname(in_image.original_filename)
        raise ext if ext !~ /\.(bmp|gif|jpe?g|png)$/i
        Magick::Image.from_blob(in_image.read).shift
        in_image.rewind
      rescue
        errors.add :image_id, :invalid
      end
    end

    def update_relation_image_member
      return unless member
      image.update_attributes(member_id: member.id)
    end
  end
end
