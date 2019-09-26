module SS::LiquidFilters
  def ss_date(input, format = nil)
    date = Liquid::Utils.to_date(input)
    return input unless date

    date = date.to_date

    if format.blank?
      return I18n.l(date)
    end

    format = format.to_s
    available_formats = I18n.t("date.formats").keys
    if available_formats.include?(format.to_sym)
      I18n.l(date, format: format.to_sym)
    else
      date.strftime(format)
    end
  end

  def ss_time(input, format = nil)
    date = Liquid::Utils.to_date(input)
    return input unless date

    date = date.in_time_zone

    if format.blank?
      return I18n.l(date)
    end

    format = format.to_s
    available_formats = I18n.t("time.formats").keys
    if available_formats.include?(format.to_sym)
      I18n.l(date, format: format.to_sym)
    else
      date.strftime(format)
    end
  end

  def pluralize(input)
    input.to_s.pluralize
  end

  def singularize(input)
    input.to_s.singularize
  end

  def camelize(input)
    input.to_s.camelize
  end

  def underscore(input)
    input.to_s.underscore
  end

  def titleize(input)
    input.to_s.titleize
  end

  def dasherize(input)
    input.to_s.dasherize
  end

  def parameterize(input)
    input.to_s.parameterize
  end

  def tableize(input)
    input.to_s.tableize
  end

  def classify(input)
    input.to_s.classify
  end

  def phone(input)
    input.to_s(:phone)
  end

  def currency(input)
    input.to_s(:currency)
  end

  def percentage(input)
    input.to_s(:percentage)
  end

  def delimited(input)
    input.to_s(:delimited)
  end

  def rounded(input)
    input.to_s(:rounded)
  end

  def human(input)
    input.to_s(:human)
  end

  def human_size(input)
    input.to_s(:human_size)
  end

  def ss_append(input, string)
    string = string.to_s
    if input.is_a?(Array) || input.is_a?(Hash) || input.is_a?(Enumerable)
      InputIterator.new(input).map { |v| v.to_s + string }
    else
      input.to_s + string
    end
  end

  def ss_prepend(input, string)
    string = string.to_s
    if input.is_a?(Array) || input.is_a?(Hash) || input.is_a?(Enumerable)
      InputIterator.new(input).map { |v| string + v.to_s }
    else
      string + input.to_s
    end
  end

  def ss_img_src(input)
    ::SS::Html.extract_img_src(input.to_s)
  end

  def expand_path(input, path)
    return input if input.blank?

    path = path.to_s
    input = input.to_s
    if path.start_with?("http://", "https://")
      ::URI.join(path, input).to_s
    else
      ::File.expand_path(input, path)
    end
  end

  def sanitize(input)
    ApplicationController.helpers.sanitize(input.to_s)
  end
end
