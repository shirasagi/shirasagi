module SS::ErrorMessagesFor
  extend ActiveSupport::Concern

  def error_messages_for(object, header_message: nil)
    object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
    object = convert_to_model(object)
    return if object.nil?

    object_name = object.class.model_name.human.downcase if object.class.respond_to?(:model_name)
    object_name ||= object

    count = object.errors.count
    return if count == 0

    html = { id: 'errorExplanation', class: 'errorExplanation' }
    I18n.with_options(scope: %i[activerecord errors template]) do |locale|
      # be careful, header_message can be nil, false and arbitrary string, and nil means no header
      header_message = locale.t(:header, count: count, model: object_name.to_s.tr('_', ' ')) if header_message.nil?
      message_body = locale.t(:body)

      error_messages = object.errors.full_messages.map do |msg|
        content_tag(:li, msg)
      end.join.html_safe

      contents = ''
      contents << content_tag(:h2, header_message) if header_message.present?
      contents << content_tag(:p, message_body) if message_body.present?
      contents << content_tag(:ul, error_messages)

      content_tag(:div, contents.html_safe, html)
    end
  end
end
