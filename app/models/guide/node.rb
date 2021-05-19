class Guide::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^guide\//) }
  end

  class Guide
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include ::Guide::Addon::ProcedureSetting
    include ::Guide::Addon::GuideList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "guide/guide") }
  end
end
