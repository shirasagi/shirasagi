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
    include Inquiry::Addon::ReleasePlan
    include Inquiry::Addon::ReceptionPlan
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    has_many :columns, class_name: "Inquiry::Column"
    has_many :answers, class_name: "Inquiry::Answer"

    after_validation :set_released, if: -> { public? }
    default_scope ->{ where(route: "inquiry/form") }

    private

    def set_released
      now = Time.zone.now
      self.released ||= now
      self.first_released ||= now
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
      cond = []
      interpret_conditions(options.reverse_merge(request_dir: false)) do |site, content_or_path|
        if content_or_path.is_a?(Cms::Content)
          node = content_or_path
          cond << { site_id: site.id, filename: /^#{::Regexp.escape(node.filename)}\//, depth: node.depth + 1 }
        elsif content_or_path == :root_contents
          cond << { site_id: site.id, filename: /^[^\/]+$/, depth: 1 }
          next
        elsif content_or_path.end_with?("*")
          # wildcard
          cond << { site_id: site.id, filename: /^#{::Regexp.escape(content_or_path[0..-2])}/ }
          next
        else
          node = Cms::Node.site(site).filename(content_or_path).first rescue nil
          next unless node

          cond << { site_id: site.id, filename: node.filename }
        end
      end

      { '$or' => cond }
    end
  end
end
