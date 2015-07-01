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
    end

    private
      def validate_thumb
        file = relation_file(:thumb)
        errors.add :thumb_id, :thums_is_not_an_image unless file.image?
      end
  end
end
