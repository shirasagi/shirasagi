module Chat::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^chat\//) }
  end

  class Bot
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Chat::Addon::Text
    include Cms::Addon::ForMemberNode
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Lgwan::Node

    default_scope ->{ where(route: "chat/bot") }
  end
end
