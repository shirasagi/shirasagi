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
    include Cms::Addon::Meta
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::DefaultReleasePlan
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/page") }
  end

  class ImportNode
    include Cms::Model::Node
    include Cms::Addon::NodeSetting
    include Cms::Addon::Meta
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup
    include Cms::Addon::Import::Page

    default_scope ->{ where(route: "cms/import_node") }
  end

  class << self
    @@plugins = []

    def plugin(path)
      name = I18n.t("modules.#{path.sub(/\/.*/, '')}", default: path.titleize)
      name << "/" + I18n.t("cms.nodes.#{path}", default: path.titleize)
      @@plugins << [name, path, plugin_enabled?(path)]
    end

    def plugin_enabled?(path)
      paths = path.split('/')
      paths.insert(1, 'node')

      section = paths.shift
      return true unless SS.config.respond_to?(section)

      config = SS.config.send(section).to_h.stringify_keys
      while paths.length > 1
        path = paths.shift
        return true unless config.key?(path)
        config = config[path]
        return true unless config.is_a?(Hash)
      end

      config.fetch(paths.last, 'enabled') != 'disabled'
    end

    def plugins
      @@plugins
    end

    def modules
      keys = @@plugins.select { |m| m[2] }.map {|m| m[1].sub(/\/.*/, "") }.uniq
      keys.map {|key| [I18n.t("modules.#{key}", default: key.to_s.titleize), key] }
    end
  end
end
