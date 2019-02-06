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

    date = date.to_time

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
end
