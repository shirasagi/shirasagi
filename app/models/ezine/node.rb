module Ezine::Node
  class Base
    include Cms::Model::Node
    include Multilingual::Addon::Node

    default_scope ->{ where(route: /^ezine\//) }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Ezine::Addon::Signature
    include Ezine::Addon::SenderAddress
    include Ezine::Addon::Reply
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    has_many :columns, class_name: "Ezine::Column"

    default_scope ->{ where(route: "ezine/page") }

    def members_to_deliver(model = Ezine::Member)
      model.site(site).where(node_id: id).enabled
    end

    def test_members_to_deliver
      members_to_deliver(Ezine::TestMember)
    end

    include Multilingual::Addon::Node
  end

  class MemberPage
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Ezine::Addon::Signature
    include Ezine::Addon::SenderAddress
    include Ezine::Addon::SubscriptionConstraint
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    has_many :members, class_name: "Cms::Member"

    default_scope ->{ where(route: "ezine/member_page") }

    def condition_hash
      h = super
      h['$or'] << { filename: /^#{filename}\//, depth: self.depth + 1 }
      h
    end

    def members_to_deliver
      Ezine::CmsMemberWrapper.site(site).where(subscription_ids: id).and_enabled
    end

    def test_members_to_deliver
      Ezine::TestMember.site(site).where(node_id: id).enabled
    end

    include Multilingual::Addon::Node
  end

  class Backnumber
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ezine/backnumber") }

    def condition_hash
      h = super
      h['$or'] << { filename: /^#{parent.filename}\//, depth: self.depth }
      h
    end

    include Multilingual::Addon::Node
  end

  class CategoryBase
    include Cms::Model::Node
    include Multilingual::Addon::Node

    default_scope ->{ where(route: /^ezine\/category_/) }
  end

  class CategoryNode
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Multilingual::Addon::Node

    default_scope ->{ where(route: "ezine/category_node") }
  end
end
