module PublicBoard::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^board\//) }
  end

  class Post
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include PublicBoard::Addon::List
    include Cms::Addon::Captcha
    include PublicBoard::Addon::PostSetting
    include PublicBoard::Addon::FileSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "public_board/post") }
  end
end
