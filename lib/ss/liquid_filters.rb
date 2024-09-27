module SS::LiquidFilters
  AVAILABLE_DATE_FORMATS = I18n.t("date.formats").keys.freeze
  AVAILABLE_TIME_FORMATS = I18n.t("time.formats").keys.freeze

  module Utils
    def self.stringify_number(input, format)
      return input unless input.numeric?
      ::Liquid::Utils.to_number(input).to_fs(format)
    end
  end

  def ss_date(input, format = nil)
    date = Liquid::Utils.to_date(input)
    return input unless date

    date = date.to_date

    if format.blank?
      return I18n.l(date)
    end

    format = format.to_s
    format = format.to_sym if AVAILABLE_DATE_FORMATS.include?(format.to_sym)
    I18n.l(date, format: format)
  end

  def ss_time(input, format = nil)
    date = Liquid::Utils.to_date(input)
    return input unless date

    date = date.in_time_zone

    if format.blank?
      return I18n.l(date)
    end

    format = format.to_s
    format = format.to_sym if AVAILABLE_TIME_FORMATS.include?(format.to_sym)
    I18n.l(date, format: format)
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
    Utils.stringify_number(input, :phone)
  end

  def currency(input)
    Utils.stringify_number(input, :currency)
  end

  def percentage(input)
    Utils.stringify_number(input, :percentage)
  end

  def delimited(input)
    Utils.stringify_number(input, :delimited)
  end

  def rounded(input)
    Utils.stringify_number(input, :rounded)
  end

  def human(input)
    Utils.stringify_number(input, :human)
  end

  def human_size(input)
    Utils.stringify_number(input, :human_size)
  end

  def ss_br(input)
    return input if input.blank?
    ApplicationController.helpers.br(input)
  end

  def ss_append(input, string)
    string = string.to_s
    if input.is_a?(Array) || input.is_a?(Hash) || input.is_a?(Enumerable)
      Liquid::StandardFilters::InputIterator.new(input, context).map { |v| v.to_s + string }
    else
      input.to_s + string
    end
  end

  def ss_prepend(input, string)
    string = string.to_s
    if input.is_a?(Array) || input.is_a?(Hash) || input.is_a?(Enumerable)
      Liquid::StandardFilters::InputIterator.new(input, context).map { |v| string + v.to_s }
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

  def public_list(input, limit = nil)
    node = input.try(:delegatee)
    return unless node
    return unless node.is_a?(Cms::Model::Node)
    criteria = Cms::Page.public_list(site: node.site, node: node)
    criteria = criteria.limit(limit) if limit.present?
    criteria.to_a
  end

  def search_column_value(page, *args)
    return nil if !page.respond_to?(:values)
    return nil if !args.is_a?(Array)
    page.values.to_a.find { |value| args.include?(value.name) }
  end

  def filter_by_column_value(pages, key_value)
    key, value = key_value.split(".")
    return [] if pages.blank?
    return [] if key.blank?
    return [] if value.blank?
    pages.select do |page|
      page.column_values.to_a.index { |v| v.column.try(:name) == key && v.value == value }
    end
  end

  def sort_by_column_value(pages, key)
    return [] if pages.blank?
    return [] if key.blank?
    sorted = []
    pages.each do |page|
      value = page.column_values.to_a.find { |value| value.column.try(:name) == key }
      sorted << [value.try(:value), page]
    end
    sorted.sort_by { |item| item[0] }.map { |item| item[1] }
  end

  def same_name_pages(input, filename = nil)
    page = input.try(:delegatee)
    return unless page
    return unless page.is_a?(Cms::Model::Page)
    criteria = Cms::Page.site(page.site)
    criteria = criteria.where(filename: /\A#{filename}\//) if filename.present?
    criteria.where(name: page.name).nin(id: page.id).to_a
  end

  def event_active_recurrences(input)
    recurrences = Array(input)
    date = Time.zone.today

    recurrences.select { |recurrence| recurrence.collect_event_dates.any? { |event_date| date <= event_date } }
  end

  def event_recurrence_summary(input)
    Event.recurrence_summary(input)
  end
end
