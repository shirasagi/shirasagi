module Garbage::Addon
  module K5374::Collection
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :center, type: String
      field :garbage_type, type: Array, default: []

      permit_params :center, :garbage_type
      permit_params garbage_type: [:field, :value, :view, :remarks]

      validate :validate_garbage_type
    end

    def validate_garbage_type
      return if garbage_type.blank?
      self.garbage_type = garbage_type.select { |item| item["field"].present? }
    end
  end
end
