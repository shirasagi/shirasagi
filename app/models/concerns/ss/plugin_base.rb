module SS::PluginBase
  extend ActiveSupport::Concern
  include ActiveModel::Model

  included do
    cattr_accessor(:scope, instance_accessor: false)
    attr_accessor :plugin_type, :path
    attr_writer :module_key
  end

  def disabled?
    !enabled?
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

  def module_key
    @module_key ||= path.split('/', 2).first
  end

  def i18n_module_name
    key = module_key
    I18n.t("modules.#{key}", default: key.titleize)
  end
  alias module_name i18n_module_name

  def i18n_name_only
    I18n.t("#{self.class.scope}.#{plugin_type.pluralize}.#{path}", default: path.split('/', 2).last.titleize)
  end
  alias name_only i18n_name_only

  def i18n_name
    [ i18n_module_name, i18n_name_only ].join("/")
  end
  alias name i18n_name
end
