module Jmaxml::Addon::Action::SwitchUrgency
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    belongs_to :urgency_layout, class_name: "Cms::Layout"
    validates :urgency_layout_id, presence: true
    permit_params :urgency_layout_id
  end
end
