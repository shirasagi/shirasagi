module Garbage::Addon
  module Collection
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :center, type: String
      field :garbage_type, type: Cms::Extensions::GarbageType

      permit_params :center, :garbage_type
      permit_params garbage_type: [ :field, :value, :view ]
    end
  end
end
