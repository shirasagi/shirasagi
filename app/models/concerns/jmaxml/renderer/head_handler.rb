module Jmaxml::Renderer::HeadHandler
  extend ActiveSupport::Concern
  include Jmaxml::Helper::HeadHandler

  included do
    template_variable_handler(:head_title, :template_variable_handler_head_title)
    template_variable_handler(:headline_text, :template_variable_handler_headline_text)
    template_variable_handler(:target_time, :template_variable_handler_target_time)
    template_variable_handler(:info_type, :template_variable_handler_info_type)
  end

  private
  def template_variable_handler_head_title(*_)
    head_title
  end

  def template_variable_handler_headline_text(*_)
    head_headline_text
  end

  def template_variable_handler_target_time(*_)
    head_target_datetime_format
  end

  def template_variable_handler_info_type(*_)
    head_info_type
  end
end
