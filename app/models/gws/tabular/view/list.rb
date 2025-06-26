class Gws::Tabular::View::List < Gws::Tabular::View::Base
  include Gws::Addon::Tabular::ListView
  include Gws::Addon::ReadableSetting
  include Gws::Addon::GroupPermission

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(
        plugin_type: "tabular_view", path: self.name.underscore, module_key: 'gws/tabular', model_class: self)
    end
  end

  def view_paths
    []
  end

  def index_template_path
    "gws/tabular/files/list/index"
  end
end
