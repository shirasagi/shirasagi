module Opendata::IdeaTemplateVariables
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:idea_name, :template_variable_handler_idea_name)
    template_variable_handler(:idea_url, :template_variable_handler_idea_url)
    template_variable_handler(:idea_updated, :template_variable_handler_idea_updated)
    template_variable_handler('idea_updated.default') { |name, issuer| template_variable_handler_idea_updated(name, issuer, :default) }
    template_variable_handler('idea_updated.iso') { |name, issuer| template_variable_handler_idea_updated(name, issuer, :iso) }
    template_variable_handler('idea_updated.long') { |name, issuer| template_variable_handler_idea_updated(name, issuer, :long) }
    template_variable_handler('idea_updated.short') { |name, issuer| template_variable_handler_idea_updated(name, issuer, :short) }
    template_variable_handler(:idea_state, :template_variable_handler_idea_state)
    template_variable_handler(:idea_point, :template_variable_handler_idea_point)
    template_variable_handler(:idea_datasets, :template_variable_handler_idea_datasets)
    template_variable_handler(:idea_apps, :template_variable_handler_idea_apps)
  end

  private
    def template_variable_handler_idea_name(name, issuer)
      ERB::Util.html_escape self.name
    end

    def template_variable_handler_idea_url(name, issuer)
      ERB::Util.html_escape "#{issuer.url}#{id}/"
    end

    def template_variable_handler_idea_updated(name, issuer, format = nil)
      format = I18n.t("opendata.labels.updated") if format.nil?
      I18n.l updated, format: format
    end

    def template_variable_handler_idea_state(name, issuer)
      ERB::Util.html_escape(label :status)
    end

    def template_variable_handler_idea_point(name, issuer)
      ERB::Util.html_escape(point.to_i.to_s)
    end

    def template_variable_handler_idea_datasets(name, issuer)
      if dataset_ids.length > 0
        ERB::Util.html_escape(datasets[0].name)
      else
        ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
      end
    end

    def template_variable_handler_idea_apps(name, issuer)
      if app_ids.length > 0
        ERB::Util.html_escape(apps[0].name)
      else
        ERB::Util.html_escape(I18n.t("opendata.labels.not_exist"))
      end
    end
end
