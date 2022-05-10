module Inquiry::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^inquiry\//) }
  end

  class Form
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Inquiry::Addon::Message
    include Inquiry::Addon::Captcha
    include Inquiry::Addon::Notice
    include Inquiry::Addon::Reply
    include Inquiry::Addon::Aggregation
    include Inquiry::Addon::Faq
    include Cms::Addon::ForMemberNode
    include Cms::Addon::ReleasePlan
    include Inquiry::Addon::ReceptionPlan
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    has_many :columns, class_name: "Inquiry::Column"
    has_many :answers, class_name: "Inquiry::Answer"

    default_scope ->{ where(route: "inquiry/form") }

    def serve_static_file?
      (site.try(:inquiry_form_id) == id) ? false : super
    end
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "inquiry/node") }

    def condition_hash(options = {})
      super(options.reverse_merge(category: false))
    end
  end
end
