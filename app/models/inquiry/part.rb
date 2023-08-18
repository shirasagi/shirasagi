module Inquiry::Part
  class Feedback
    include Cms::Model::Part
    include Inquiry::Addon::FeedbackSetting
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "inquiry/feedback") }
  end
end
