module SS::PluginBase
  extend ActiveSupport::Concern
  include ActiveModel::Model

  included do
    cattr_accessor(:scope, instance_accessor: false)
    attr_accessor :plugin_type, :path
  end

  def enabled?
    settings = SS.config.try(self.class.scope)
    return true if settings.blank?

    if plugin_type == 'part'
      puts 'part'
    end

    plugin_settings = settings.try(plugin_type.pluralize)
    return true if plugin_settings.blank?

    part_settings = plugin_settings[path]
    return true if part_settings.blank?

    !part_settings.fetch('disable', false)
  end

  def i18n_name
    module_name = path.split('/', 2).first
    name = I18n.t("modules.#{module_name}", default: path.titleize)
    name << "/" + I18n.t("#{self.class.scope}.#{plugin_type.pluralize}.#{path}", default: path.titleize)
    name
  end

  alias name i18n_name
end
