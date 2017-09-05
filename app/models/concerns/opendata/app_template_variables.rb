module Opendata::AppTemplateVariables
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:app_name, :template_variable_handler_app_name)
    template_variable_handler(:app_url, :template_variable_handler_app_url)
    template_variable_handler(:app_updated, :template_variable_handler_app_updated)
    template_variable_handler('app_updated.default') do |name, issuer|
      template_variable_handler_app_updated(name, issuer, :default)
    end
    template_variable_handler('app_updated.iso') do |name, issuer|
      template_variable_handler_app_updated(name, issuer, :iso)
    end
    template_variable_handler('app_updated.long') do |name, issuer|
      template_variable_handler_app_updated(name, issuer, :long)
    end
    template_variable_handler('app_updated.short') do |name, issuer|
      template_variable_handler_app_updated(name, issuer, :short)
    end
    template_variable_handler(:app_state, :template_variable_handler_app_state)
    template_variable_handler(:app_point, :template_variable_handler_app_point)
  end

  private

  def template_variable_handler_app_name(name, issuer)
    ERB::Util.html_escape self.name
  end

  def template_variable_handler_app_url(name, issuer)
    ERB::Util.html_escape "#{issuer.url}#{id}/"
  end

  def template_variable_handler_app_updated(name, issuer, format = nil)
    format = I18n.t("opendata.labels.updated") if format.nil?
    I18n.l updated, format: format
  end

  def template_variable_handler_app_state(name, issuer)
    ERB::Util.html_escape(label(:status))
  end

  def template_variable_handler_app_point(name, issuer)
    ERB::Util.html_escape(point.to_i.to_s)
  end
end
