module Cms::PluginRepository
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:plugins, instance_accessor: false) { [] }
    mattr_accessor(:_plugin_type, instance_accessor: false) { 'node' }
  end

  module ClassMethods
    def plugin_type(type)
      self._plugin_type = type.singularize
    end

    def plugin(path)
      name = I18n.t("modules.#{path.sub(/\/.*/, '')}", default: path.titleize)
      name << "/" + I18n.t("cms.#{self._plugin_type.pluralize}.#{path}", default: path.titleize)
      self.plugins << [name, path, plugin_enabled?(path)]
    end

    def plugin_enabled?(path)
      paths = path.split('/')
      paths.insert(1, self._plugin_type)

      section = paths.shift
      return true unless SS.config.respond_to?(section)

      config = SS.config.send(section).to_h.stringify_keys
      while paths.present?
        path = paths.shift
        return true unless config.key?(path)
        config = config[path]
        return true unless config.is_a?(Hash)
      end

      !config.fetch('disable', false)
    end
  end
end
