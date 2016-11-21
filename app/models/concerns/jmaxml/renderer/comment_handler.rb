module Jmaxml::Renderer::CommentHandler
  extend ActiveSupport::Concern

  included do
    template_variable_handler(:forecast_comment, :template_variable_handler_forecast_comment)
    template_variable_handler(:warning_comment, :template_variable_handler_warning_comment)
    template_variable_handler(:free_form_comment, :template_variable_handler_free_form_comment)
  end

  def body_comments_forecast_comment
    comment = ''

    xpath = '/Report/Body/Comments/ForecastComment/Text/text()'
    REXML::XPath.each(@context.xmldoc, xpath) do |forecast_comment|
      forecast_comment = forecast_comment.to_s.strip

      comment << "\n" if comment.present?
      comment << forecast_comment if forecast_comment.present?
    end

    comment
  end

  def body_comments_warning_comment
    comment = ''

    xpath = '/Report/Body/Comments/WarningComment/Text/text()'
    REXML::XPath.each(@context.xmldoc, xpath) do |warning_comment|
      warning_comment = warning_comment.to_s.strip

      comment << "\n" if comment.present?
      comment << warning_comment if warning_comment.present?
    end

    comment
  end

  def body_comments_free_form_comment
    comment = ''

    REXML::XPath.each(@context.xmldoc, '/Report/Body/Comments/FreeFormComment/text()') do |forecast_comment|
      c = REXML::XPath.first(forecast_comment, 'Text/text()').to_s.strip.presence
      comment << "\n" if comment.present?
      comment << c if c.present?
    end

    comment
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
