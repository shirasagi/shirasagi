module SS::PluginBase
  extend ActiveSupport::Concern
  include ActiveModel::Model

  included do
    cattr_accessor(:scope, instance_accessor: false)
    attr_accessor :plugin_type, :path
  end

  def enabled?
    paths = path.split('/')
    paths.insert(1, plugin_type)

    section = paths.shift
    return true unless SS.config.respond_to?(section)

    config = SS.config.send(section).to_h.stringify_keys
    while paths.present?
      path = paths.shift
      return true unless config.key?(path)
      config = config[path]
      return true unless config.is_a?(Hash)
    end

    !config.fetch('disable', false)
  end

  def i18n_name
    module_name = path.split('/', 2).first
    name = I18n.t("modules.#{module_name}", default: path.titleize)
    name << "/" + I18n.t("#{self.class.scope}.#{plugin_type.pluralize}.#{path}", default: path.titleize)
    name
  end

  alias name i18n_name
end
