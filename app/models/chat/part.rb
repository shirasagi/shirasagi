class Chat::Part
  include Cms::Model::Part
  include SS::PluginRepository

  index({ site_id: 1, filename: 1 }, { unique: true })

  plugin_type "part"

  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^chat\//) }
  end

  class Bot
    include Cms::Model::Part
    include Chat::Addon::Path
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "chat/bot") }
  end
end
