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
    include Inquiry::Addon::ReleasePlan
    include Inquiry::Addon::ReceptionPlan
    include Inquiry::Addon::Aggregation
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
    include Cms::Addon::Release
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "inquiry/node") }

    def condition_hash(opts = {})
      cond = []
      cond << { filename: /^#{filename}\//, depth: depth + 1 }

      conditions.each do |url|
        # regex
        if url =~ /\/\*$/
          filename = url.sub(/\/\*$/, "")
          cond << { filename: /^#{filename}\// }
          next
        end

        s = cur_site || site rescue nil
        node = Cms::Node.site(s).filename(url).first
        next unless node

        cond << { filename: node.filename }
      end

      { '$or' => cond }
    end
  end
end
