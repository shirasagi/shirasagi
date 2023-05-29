class Guidance::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^guidance\//) }
  end

  class Guide
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Guidance::Addon::QuestionNode

    default_scope ->{ where(route: "guidance/guide") }
  end
end
