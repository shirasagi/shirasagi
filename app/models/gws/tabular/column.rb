class Gws::Tabular::Column
  include SS::PluginRepository

  plugin_class Gws::Plugin
  plugin_type "tabular_column"

  def self.route_options
    plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.i18n_name, plugin.path] }
  end

  def self.column_type_options(cur_form:)
    items = {}

    Gws::Tabular::Column.route_options.each do |name, path|
      mod = path.sub(/\/.*/, '')
      items[mod] = { name: I18n.t("modules.#{mod}"), items: [] } if !items[mod]
      items[mod][:items] << [ name.sub(/.*\//, ''), path ]
    end

    items
  end
end
