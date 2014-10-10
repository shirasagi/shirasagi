module Urgency::Addon
  module Layout
    extend ActiveSupport::Concern
    extend SS::Addon

    set_order 10

    included do
      belongs_to :urgency_default_layout, class_name: "Cms::Layout"
      permit_params :urgency_default_layout_id

      validates :urgency_default_layout_id, presence: true
    end
  end
end
