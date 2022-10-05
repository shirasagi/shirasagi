module Gws::PluginRepository
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:plugins, instance_accessor: false) { [] }
    mattr_accessor(:_plugin_type, instance_accessor: false) { 'node' }
  end

  class Plugin
    include ActiveModel::Model

    attr_accessor :plugin_type, :path

    def enabled?
      paths = path.split('/')
      paths.insert(1, plugin_type)

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

    def i18n_name
      module_name = path.split('/', 2).first
      name = I18n.t("modules.#{module_name}", default: path.titleize)
      name << "/" + I18n.t("gws.#{plugin_type.pluralize}.#{path}", default: path.titleize)
      name
    end
  end

  module ClassMethods
    def plugin_type(type)
      self._plugin_type = type.singularize
    end

    def plugin(path)
      self.plugins << Plugin.new(plugin_type: self._plugin_type, path: path)
    end

    def plugin_enabled?(path)
      plugin = find_plugin_by_path(path)
      return if plugin.blank?

      plugin.enabled?
    end

    def modules
      keys = self.plugins.select { |m| m[2] }.map { |m| m[1].sub(/\/.*/, "") }.uniq
      keys.map { |key| [I18n.t("modules.#{key}", default: key.to_s.titleize), key] }
    end
  end
end
