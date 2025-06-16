module InquirySecond::Part
  class Feedback
    include Cms::Model::Part
    include InquirySecond::Addon::FeedbackSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "inquiry_second/feedback") }
  end
end
