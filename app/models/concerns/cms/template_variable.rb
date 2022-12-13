module Cms::TemplateVariable
  extend ActiveSupport::Concern
  include SS::TemplateVariable

  included do
    template_variable_handler(:id, :template_variable_handler_name)
    template_variable_handler(:name, :template_variable_handler_name)
    template_variable_handler(:url, :template_variable_handler_name)
    template_variable_handler(:html, :template_variable_handler_html)
    template_variable_handler(:index_name) { |name, issuer| template_variable_handler_name(:name_for_index, issuer) }
    template_variable_handler(:class, :template_variable_handler_class)
    template_variable_handler(:class_categories, :template_variable_handler_class_categories)
    template_variable_handler(:new, :template_variable_handler_new)
    template_variable_handler(:date, :template_variable_handler_date)
    template_variable_handler('date.default') { |name, issuer| template_variable_handler_date(name, issuer, :default) }
    template_variable_handler('date.iso') { |name, issuer| template_variable_handler_date(name, issuer, :iso) }
    template_variable_handler('date.long') { |name, issuer| template_variable_handler_date(name, issuer, :long) }
    template_variable_handler('date.short') { |name, issuer| template_variable_handler_date(name, issuer, :short) }
    template_variable_handler(:time, :template_variable_handler_time)
    template_variable_handler('time.default') { |name, issuer| template_variable_handler_time(name, issuer, :default) }
    template_variable_handler('time.iso') { |name, issuer| template_variable_handler_time(name, issuer, :iso) }
    template_variable_handler('time.long') { |name, issuer| template_variable_handler_time(name, issuer, :long) }
    template_variable_handler('time.short') { |name, issuer| template_variable_handler_time(name, issuer, :short) }
    template_variable_handler(:current, :template_variable_handler_current)
  end

  def name_for_index
    try(:index_name) || name
  end

  private

  def template_variable_handler_name(name, issuer)
    ERB::Util.html_escape self.send(name)
  end

  def template_variable_handler_html(name, issuer)
    return nil unless respond_to?(name)
    self.send(name).present? ? self.send(name).html_safe : nil
  end

  def template_variable_handler_class(name, issuer)
    return nil if try(:basename).blank?
    SS.config.cms.template_variable_handler_prefix['class'] + self.basename.sub(/\..*/, "").dasherize
  end

  def template_variable_handler_class_categories(name, issuer)
    return nil if try(:categories).blank?
    self.categories.and_public.order_by(order: 1, name: 1).map { |cate| SS.config.cms.template_variable_handler_prefix['class_categories'] + cate.basename }.join(" ")
  end

  def template_variable_handler_new(name, issuer)
    issuer.respond_to?(:in_new_days?) && issuer.in_new_days?(self.date) ? "new" : nil
  end

  def template_variable_handler_date(name, issuer, format = nil)
    if format.nil?
      I18n.l self.date.to_date
    else
      I18n.l self.date.to_date, format: format.to_sym
    end
  end

  def template_variable_handler_time(name, issuer, format = nil)
    if format.nil?
      I18n.l self.date
    else
      I18n.l self.date, format: format.to_sym
    end
  end

  def template_variable_handler_current(name, issuer)
    false
  end
end
