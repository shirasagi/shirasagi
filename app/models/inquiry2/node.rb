module Inquiry2::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^inquiry2\//) }
  end

  class Form
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Inquiry2::Addon::Message
    include Inquiry2::Addon::Captcha
    include Inquiry2::Addon::Notice
    include Inquiry2::Addon::Reply
    # include Inquiry2::Addon::Aggregation
    include Inquiry2::Addon::Faq
    include Inquiry2::Addon::ColumnSetting
    include Cms::Addon::ForMemberNode
    include Cms::Addon::ReleasePlan
    include Inquiry2::Addon::ReceptionPlan
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    has_many :answers, foreign_key: :node_id, class_name: "Inquiry2::Answer"

    default_scope ->{ where(route: "inquiry2/form") }

    def serve_static_file?
      (site.try(:inquiry2_form_id) == id) ? false : super
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

    default_scope ->{ where(route: "inquiry2/node") }

    def condition_hash(options = {})
      super(options.reverse_merge(category: false))
    end
  end
end
