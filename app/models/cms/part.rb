class Cms::Part
  include Cms::Model::Part

  index({ site_id: 1, filename: 1 }, { unique: true })

  class Base
    include Cms::Model::Part

    default_scope ->{ where(route: /^cms\//) }
  end

  class Free
    include Cms::Model::Part
    include Cms::Addon::Html
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/free") }
  end

  class Node
    include Cms::Model::Part
    include Cms::Addon::NodeList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/node") }
  end

  class Page
    include Cms::Model::Part
    include Cms::Addon::PageList
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/page") }
  end

  class Tabs
    include Cms::Model::Part
    include Cms::Addon::Tabs
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/tabs") }
  end

  class Crumb
    include Cms::Model::Part
    include Cms::Addon::Crumb
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/crumb") }
  end

  class SnsShare
    include Cms::Model::Part
    include Cms::Addon::SnsShare
    include Cms::Addon::Release
    include Cms::Addon::GroupPermission
    include History::Addon::Backup

    default_scope ->{ where(route: "cms/sns_share") }
  end

  class << self
    @@plugins = []

    def plugin(path)
      name = I18n.t("modules.#{path.sub(/\/.*/, '')}", default: path.titleize)
      name << "/" + I18n.t("cms.parts.#{path}", default: path.titleize)
      @@plugins << [name, path, plugin_enabled?(path)]
    end

    def plugin_enabled?(path)
      paths = path.split('/')
      paths.insert(1, 'part')

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
  end
end
