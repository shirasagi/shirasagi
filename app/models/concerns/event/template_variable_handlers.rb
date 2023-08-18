module Event::TemplateVariableHandlers
  extend ActiveSupport::Concern

  included do
    template_variable_handler('event_dates') do |name, issuer|
      template_variable_handler_event_dates(name, issuer)
    end
    template_variable_handler('event_dates.default') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :default)
    end
    template_variable_handler('event_dates.default_full') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :default_full)
    end
    template_variable_handler('event_dates.iso') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :iso)
    end
    template_variable_handler('event_dates.iso_full') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :iso_full)
    end
    template_variable_handler('event_dates.long') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :long)
    end
    template_variable_handler('event_dates.full') do |name, issuer|
      template_variable_handler_event_dates(name, issuer, :full)
    end
    template_variable_handler('event_deadline') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer)
    end
    template_variable_handler('event_deadline.default') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer, :default)
    end
    template_variable_handler('event_deadline.iso') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer, :iso)
    end
    template_variable_handler('event_deadline.long') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer, :long)
    end
    template_variable_handler('event_deadline.full') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer, :full)
    end
    template_variable_handler('event_deadline.short') do |name, issuer|
      template_variable_handler_event_deadline(name, issuer, :short)
    end
  end
end
