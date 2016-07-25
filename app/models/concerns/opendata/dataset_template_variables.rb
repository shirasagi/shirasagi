module Opendata::DatasetTemplateVariables
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:dataset_name, :template_variable_handler_dataset_name)
    template_variable_handler(:dataset_url, :template_variable_handler_dataset_url)
    template_variable_handler(:dataset_updated, :template_variable_handler_dataset_updated)
    template_variable_handler('dataset_updated.default') { |name, issuer| template_variable_handler_dataset_updated(name, issuer, :default) }
    template_variable_handler('dataset_updated.iso') { |name, issuer| template_variable_handler_dataset_updated(name, issuer, :iso) }
    template_variable_handler('dataset_updated.long') { |name, issuer| template_variable_handler_dataset_updated(name, issuer, :long) }
    template_variable_handler('dataset_updated.short') { |name, issuer| template_variable_handler_dataset_updated(name, issuer, :short) }
    template_variable_handler(:dataset_state, :template_variable_handler_dataset_state)
    template_variable_handler(:dataset_point, :template_variable_handler_dataset_point)
    template_variable_handler(:dataset_downloaded, :template_variable_handler_dataset_downloaded)
    template_variable_handler(:dataset_apps_count, :template_variable_handler_dataset_apps_count)
    template_variable_handler(:dataset_ideas_count, :template_variable_handler_dataset_ideas_count)
  end

  private
    def template_variable_handler_dataset_name(name, issuer)
      ERB::Util.html_escape self.name
    end

    def template_variable_handler_dataset_url(name, issuer)
      ERB::Util.html_escape "#{issuer.url}#{id}/"
    end

    def template_variable_handler_dataset_updated(name, issuer, format = nil)
      format = I18n.t("opendata.labels.updated") if format.nil?
      I18n.l updated, format: format
    end

    def template_variable_handler_dataset_state(name, issuer)
      ERB::Util.html_escape(label :status)
    end

    def template_variable_handler_dataset_point(name, issuer)
      ERB::Util.html_escape(point.to_i.to_s)
    end

    def template_variable_handler_dataset_downloaded(name, issuer)
      ERB::Util.html_escape(downloaded.to_i.to_s)
    end

    def template_variable_handler_dataset_apps_count(name, issuer)
      ERB::Util.html_escape(apps.size.to_s)
    end

    def template_variable_handler_dataset_ideas_count(name, issuer)
      ERB::Util.html_escape(ideas.size.to_s)
    end
end
