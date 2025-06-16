module SS::Addon::InquirySecondSetting
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :inquiry_second_form_id, type: Integer

    belongs_to :inquiry_second_form, class_name: "InquirySecond::Node::Form"
    permit_params :inquiry_second_form_id
  end
end
