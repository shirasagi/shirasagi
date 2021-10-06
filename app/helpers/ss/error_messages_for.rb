module SS::ErrorMessagesFor
  extend ActiveSupport::Concern

  # Returns a string with a <tt>DIV</tt> containing all of the error messages for the objects located as instance variables by the names
  # given.  If more than one object is specified, the errors for the objects are displayed in the order that the object names are
  # provided.
  #
  # This <tt>DIV</tt> can be tailored by the following options:
  #
  # * <tt>:header_tag</tt> - Used for the header of the error div (default: "h2").
  # * <tt>:id</tt> - The id of the error div (default: "errorExplanation").
  # * <tt>:class</tt> - The class of the error div (default: "errorExplanation").
  # * <tt>:object</tt> - The object (or array of objects) for which to display errors,
  #   if you need to escape the instance variable convention.
  # * <tt>:object_name</tt> - The object name to use in the header, or any text that you prefer.
  #   If <tt>:object_name</tt> is not set, the name of the first object will be used.
  # * <tt>:header_message</tt> - The message in the header of the error div.  Pass +nil+
  #   or an empty string to avoid the header message altogether. (Default: "X errors
  #   prohibited this object from being saved").
  # * <tt>:message</tt> - The explanation message after the header message and before
  #   the error list.  Pass +nil+ or an empty string to avoid the explanation message
  #   altogether. (Default: "There were problems with the following fields:").
  #
  # To specify the display for one object, you simply provide its name as a parameter.
  # For example, for the <tt>@user</tt> model:
  #
  #   error_messages_for 'user'
  #
  # You can also supply an object:
  #
  #   error_messages_for @user
  #
  # This will use the last part of the model name in the presentation. For instance, if
  # this is a MyKlass::User object, this will use "user" as the name in the String. This
  # is taken from MyKlass::User.model_name.human, which can be overridden.
  #
  # To specify more than one object, you simply list them; optionally, you can add an extra <tt>:object_name</tt> parameter, which
  # will be the name used in the header message:
  #
  #   error_messages_for 'user_common', 'user', :object_name => 'user'
  #
  # You can also use a number of objects, which will have the same naming semantics
  # as a single object.
  #
  #   error_messages_for @user, @post
  #
  # If the objects cannot be located as instance variables, you can add an extra <tt>:object</tt> parameter which gives the actual
  # object (or array of objects to use):
  #
  #   error_messages_for 'user', :object => @question.user
  #
  # NOTE: This is a pre-packaged presentation of the errors with embedded strings and a certain HTML structure. If what
  # you need is significantly different from the default presentation, it makes plenty of sense to access the <tt>object.errors</tt>
  # instance yourself and set it up. View the source of this method to see how easy it is.
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys

    objects = Array.wrap(options.delete(:object) || params).map do |object|
      object = instance_variable_get("@#{object}") unless object.respond_to?(:to_model)
      object = convert_to_model(object)

      if object.class.respond_to?(:model_name)
        options[:object_name] ||= object.class.model_name.human.downcase
      end

      object
    end

    objects.compact!
    count = objects.inject(0) {|sum, object| sum + object.errors.count }

    unless count.zero?
      html = {}
      [:id, :class].each do |key|
        if options.include?(key)
          value = options[key]
          html[key] = value unless value.blank?
        else
          html[key] = 'errorExplanation'
        end
      end
      options[:object_name] ||= params.first

      I18n.with_options :locale => options[:locale], :scope => [:activerecord, :errors, :template] do |locale|
        header_message = if options.include?(:header_message)
          options[:header_message]
        else
          locale.t :header, :count => count, :model => options[:object_name].to_s.gsub('_', ' ')
        end

        message = options.include?(:message) ? options[:message] : locale.t(:body)

        error_messages = objects.sum do |object|
          object.errors.full_messages.map do |msg|
            content_tag(:li, msg)
          end
        end.join.html_safe

        contents = ''
        contents << content_tag(options[:header_tag] || :h2, header_message) unless header_message.blank?
        contents << content_tag(:p, message) unless message.blank?
        contents << content_tag(:ul, error_messages)

        content_tag(:div, contents.html_safe, html)
      end
    else
      ''
    end
  end
end
