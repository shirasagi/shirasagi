module Uploader::Node
  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^uploader\//) }
  end

  class File
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Release
    include Cms::Addon::Meta
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "uploader/file") }
  end
end
