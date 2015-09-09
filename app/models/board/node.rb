module Board::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^board\//) }
  end

  class Post
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Board::Addon::List
    include Cms::Addon::Captcha
    include Board::Addon::PostSetting
    include Board::Addon::FileSetting
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "board/post") }
  end
end
