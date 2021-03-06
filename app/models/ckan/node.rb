module Ckan::Node
  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Ckan::Addon::ItemList
    include Ckan::Addon::Server
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "ckan/page") }
  end
end
