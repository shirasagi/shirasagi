module Jmaxml::Renderer::CommentHandler
  extend ActiveSupport::Concern
  include Jmaxml::Helper::CommentHandler

  included do
    template_variable_handler(:forecast_comment, :template_variable_handler_forecast_comment)
    template_variable_handler(:warning_comment, :template_variable_handler_warning_comment)
    template_variable_handler(:free_form_comment, :template_variable_handler_free_form_comment)
  end

  private

  def template_variable_handler_forecast_comment(*_)
    body_comments_forecast_comment
  end

  def template_variable_handler_warning_comment(*_)
    body_comments_warning_comment
  end

  def template_variable_handler_free_form_comment(*_)
    body_comments_free_form_comment
  end
end
