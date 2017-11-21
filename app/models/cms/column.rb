class Cms::Column
  include Cms::PluginRepository

  plugin_type 'column'

  def self.route_options
    plugins.select { |name, path, enabled| enabled }.map { |name, path, enabled| [name, path] }
  end
end
