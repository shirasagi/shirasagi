module Jmaxml::Helper::CommentHandler
  extend ActiveSupport::Concern

  def body_comments_forecast_comment
    comment = ''

    xpath = '/Report/Body/Comments/ForecastComment/Text/text()'
    REXML::XPath.each(xmldoc, xpath) do |forecast_comment|
      forecast_comment = forecast_comment.to_s.strip

      comment << "\n" if comment.present?
      comment << forecast_comment if forecast_comment.present?
    end

    comment
  end

  def body_comments_warning_comment
    comment = ''

    xpath = '/Report/Body/Comments/WarningComment/Text/text()'
    REXML::XPath.each(xmldoc, xpath) do |warning_comment|
      warning_comment = warning_comment.to_s.strip

      comment << "\n" if comment.present?
      comment << warning_comment if warning_comment.present?
    end

    comment
  end

  def body_comments_free_form_comment
    comment = ''

    REXML::XPath.each(xmldoc, '/Report/Body/Comments/FreeFormComment/text()') do |forecast_comment|
      c = REXML::XPath.first(forecast_comment, 'Text/text()').to_s.strip.presence
      comment << "\n" if comment.present?
      comment << c if c.present?
    end

    comment
  end
end
