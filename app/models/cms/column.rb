class Cms::Column
  include SS::PluginRepository

  plugin_type 'column'

  def self.plugin(path)
    super
    type = path.sub('/', '/column/')
    type = type.classify
    model = type.constantize
    model.value_type
  end

  def self.route_options
    plugins.select { |plugin| plugin.enabled? }.map { |plugin| [plugin.name, plugin.path] }
  end
end
