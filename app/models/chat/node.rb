class Chat::Node
  include Cms::Model::Node
  include SS::PluginRepository
  include Cms::Addon::NodeSetting
  include Cms::Addon::EditorSetting
  include Cms::Addon::GroupPermission
  include Cms::Addon::ForMemberNode

  index({ site_id: 1, filename: 1 }, { unique: true })

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

    default_scope ->{ where(route: "chat/bot") }
  end
end
