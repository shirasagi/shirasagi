module Cms::Addon
  module Thumb
    extend ActiveSupport::Concern
    extend SS::Addon
    include SS::Relation::File

    included do
      attr_accessor :in_thumb
      belongs_to_file :thumb
      permit_params :in_thumb
      validate :validate_thumb, if: ->{ in_thumb.present? }

      after_generate_file :generate_thumb_public_file, if: ->{ serve_static_relation_files? } if respond_to?(:after_generate_file)
      after_remove_file :remove_thumb_public_file if respond_to?(:after_remove_file)
    end

    private
      def validate_thumb
        file = relation_file(:thumb)
        errors.add :thumb_id, :thums_is_not_an_image unless file.image?
      end

      def generate_thumb_public_file
        return if thumb.blank?
        thumb.generate_public_file
      end

      def remove_thumb_public_file
        return if thumb.blank?
        thumb.remove_public_file
      end
  end
end
