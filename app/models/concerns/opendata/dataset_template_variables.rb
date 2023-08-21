module Opendata::DatasetTemplateVariables
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:dataset_name, :template_variable_handler_dataset_name)
    template_variable_handler(:dataset_url, :template_variable_handler_dataset_url)
    template_variable_handler(:dataset_updated, :template_variable_handler_dataset_updated)
    template_variable_handler('dataset_updated.default') do |name, issuer|
      template_variable_handler_dataset_updated(name, issuer, :default)
    end
    template_variable_handler('dataset_updated.iso') do |name, issuer|
      template_variable_handler_dataset_updated(name, issuer, :iso)
    end
    template_variable_handler('dataset_updated.long') do |name, issuer|
      template_variable_handler_dataset_updated(name, issuer, :long)
    end
    template_variable_handler('dataset_updated.short') do |name, issuer|
      template_variable_handler_dataset_updated(name, issuer, :short)
    end
    template_variable_handler(:dataset_state, :template_variable_handler_dataset_state)
    template_variable_handler(:dataset_point, :template_variable_handler_dataset_point)
    template_variable_handler(:dataset_downloaded, :template_variable_handler_dataset_downloaded)
    template_variable_handler(:dataset_apps_count, :template_variable_handler_dataset_apps_count)
    template_variable_handler(:dataset_ideas_count, :template_variable_handler_dataset_ideas_count)
    template_variable_handler('class_estat_categories', :template_variable_handler_class_estat_categories)
    template_variable_handler('class_categories', :template_variable_handler_class_categories)
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
    ERB::Util.html_escape(label(:status))
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

  def template_variable_handler_class_categories(name, issuer)
    categories.to_a.map { |cate| "dataset-#{cate.basename}" }.join(" ")
  end

  def template_variable_handler_class_estat_categories(name, issuer)
    estat_categories.to_a.map { |cate| "estat-#{cate.basename}" }.join(" ")
  end
end
