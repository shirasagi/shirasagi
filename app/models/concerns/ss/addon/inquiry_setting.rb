module SS::Addon::InquirySetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :inquiry_form_id, type: Integer

    belongs_to :inquiry_form, class_name: "Inquiry::Node::Form"
    permit_params :inquiry_form_id
  end
end