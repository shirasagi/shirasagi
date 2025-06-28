module SS::Addon::Inquiry2Setting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :inquiry2_form_id, type: Integer

    belongs_to :inquiry2_form, class_name: "Inquiry2::Node::Form"
    permit_params :inquiry2_form_id
  end
end
