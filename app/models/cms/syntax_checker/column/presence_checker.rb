class Cms::SyntaxChecker::Column::PresenceChecker
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base

  attr_accessor :context, :content, :column_value, :attribute, :params

  def check
    return unless parsed_params

    case parsed_params
    in message:
      if message.is_a?(Symbol)
        presence_error = I18n.t(message, scope: "errors.messages")
      else
        presence_error = message.to_s
      end
    else
      presence_error = I18n.t(
        "errors.format", attribute: column_value.class.t(attribute), message: I18n.t("errors.messages.blank"))
    end

    if column_value[attribute].blank?
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: nil, checker: self, error: presence_error)
    end
  end
end
