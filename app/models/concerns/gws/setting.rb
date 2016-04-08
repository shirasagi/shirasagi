module Gws::Setting
  class << self
    @@plugins = []

    def plugin(plugin_module, url_lazy)
      Gws::Group.include plugin_module
      name = plugin_module.to_s.underscore.sub("/setting", "")
      name = I18n.t "modules.settings.#{name}", default: name.titleize
      @@plugins << [name, url_lazy]
    end

    def plugins
      @@plugins
    end
  end
end
