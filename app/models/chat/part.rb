module Chat::Part
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
