class Inquiry::Plugin
  include SS::PluginBase

  self.scope = 'inquiry'

  def i18n_name_only
    last_path = path.split('/', 2).last
    I18n.t(last_path, scope: "inquiry.options.input_type", default: ->(*){ last_path.titleize })
  end
end
