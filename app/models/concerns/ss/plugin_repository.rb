module SS::PluginRepository
  extend ActiveSupport::Concern

  included do
    mattr_accessor(:_plugin_class, instance_accessor: false, default: Cms::Plugin)
    mattr_accessor(:_plugin_type, instance_accessor: false, default: 'node')
    mattr_accessor(:plugins, instance_accessor: false, default: [])
  end

  module ClassMethods
    def plugin_class(klass)
      self._plugin_class = klass
    end

    def plugin_type(type)
      self._plugin_type = type.singularize
    end

    def plugin(path_or_plugin)
      if path_or_plugin.is_a?(_plugin_class)
        ret = path_or_plugin
      else
        ret = _plugin_class.new(plugin_type: self._plugin_type, path: path_or_plugin)
      end
      self.plugins << ret
      ret.registory = self if ret.respond_to?(:registory=)
      ret
    end

    def find_plugin_by_path(path)
      plugins.find { |plugin| plugin.path == path }
    end

    def plugin_enabled?(path)
      plugin = find_plugin_by_path(path)
      return if plugin.blank?

      plugin.enabled?
    end

    def modules
      keys = self.plugins.select { |plugin| plugin.enabled? }.map { |plugin| plugin.path.sub(/\/.*/, "") }.uniq
      keys.map { |key| [I18n.t("modules.#{key}", default: key.to_s.titleize), key] }
    end
  end
end
