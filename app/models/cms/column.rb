class Cms::Column
  include Cms::PluginRepository

  plugin_type 'column'

  def self.plugin(path)
    super
    type = path.sub('/', '/column/')
    type = type.classify
    model = type.constantize
    model.value_type
  end

  def self.route_options
    plugins.select { |name, path, enabled| enabled }.map { |name, path, enabled| [name, path] }
  end
end
