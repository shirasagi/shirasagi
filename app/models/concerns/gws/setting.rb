module Gws::Setting
  def self.extended(mod)
    mod.extend SS::Translation
  end

  def human_name
    name = self.to_s.underscore.sub("/setting", "")
    I18n.t "modules.settings.#{name}", default: name.titleize
  end

  def allowed?(action, user, opts = {})
    opts[:site].allowed?(action, user, opts)
  end

  class << self
    @@plugins = []

    def plugin(mod, url_lazy, opts = {})
      Gws::Group.include(mod) if opts[:include] != false
      @@plugins << [mod, url_lazy]
    end

    def plugins
      @@plugins
    end
  end
end
