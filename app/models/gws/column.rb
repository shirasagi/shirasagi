class Gws::Column
  include SS::PluginRepository

  plugin_class Gws::Plugin
  plugin_type "column"

  def self.route_options
    plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.i18n_name, plugin.path] }
  end

  def self.to_path(column_class)
    column_class.name.underscore.sub('/column/', '/')
  end
end
