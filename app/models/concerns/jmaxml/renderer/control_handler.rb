module Jmaxml::Renderer::ControlHandler
  extend ActiveSupport::Concern
  include Jmaxml::Helper::ControlHandler

  included do
    template_variable_handler(:title, :template_variable_handler_title)
    template_variable_handler(:status, :template_variable_handler_status)
    template_variable_handler(:editorial_office, :template_variable_handler_editorial_office)
    template_variable_handler(:publishing_office, :template_variable_handler_publishing_office)
  end

  private
  def template_variable_handler_title(*_)
    control_title
  end

  def template_variable_handler_status(*_)
    control_status
  end

  def template_variable_handler_editorial_office(*_)
    control_editorial_office
  end

  def template_variable_handler_publishing_office(*_)
    control_publishing_office
  end
end
