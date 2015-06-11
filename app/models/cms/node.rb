class Cms::Node
  include Cms::Model::Node
  include Cms::Addon::NodeSetting
  include Cms::Addon::GroupPermission

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Node

    default_scope ->{ where(route: /^cms\//) }
  end

  class Node
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Release
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Release
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/page") }
  end

  class << self
    @@plugins = []

    public
      def plugin(path)
        name  = I18n.t("modules.#{path.sub(/\/.*/, '')}", default: path.titleize)
        name << "/" + I18n.t("cms.nodes.#{path}", default: path.titleize)
        @@plugins << [name, path]
      end

      def plugins
        @@plugins
      end

      def modules
        keys = @@plugins.map {|m| m[1].sub(/\/.*/, "") }.uniq
        keys.map {|key| [I18n.t("modules.#{key}", default: key.to_s.titleize), key] }
      end
  end
end
