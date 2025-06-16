module InquirySecond::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^inquiry_second\//) }
  end

  class Form
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include InquirySecond::Addon::Message
    include InquirySecond::Addon::Captcha
    include InquirySecond::Addon::Notice
    include InquirySecond::Addon::Reply
    include InquirySecond::Addon::Aggregation
    include InquirySecond::Addon::Faq
    include InquirySecond::Addon::KintoneApp::Setting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::ReleasePlan
    include InquirySecond::Addon::ReceptionPlan
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    has_many :columns, foreign_key: :node_id, class_name: "InquirySecond::Column"
    has_many :answers, foreign_key: :node_id, class_name: "InquirySecond::Answer"

    default_scope ->{ where(route: "inquiry_second/form") }

    def serve_static_file?
      (site.try(:inquiry_second_form_id) == id) ? false : super
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
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "inquiry_second/node") }

    def condition_hash(options = {})
      super(options.reverse_merge(category: false))
    end
  end
end
