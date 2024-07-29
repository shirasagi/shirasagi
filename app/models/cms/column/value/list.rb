class Cms::Column::Value::List < Cms::Column::Value::Base
  field :lists, type: SS::Extensions::Lines

  permit_values lists: []

  liquidize do
    export :list_type do
      column.list_type
    end
    export :lists
  end

  class << self
    def build_mongo_query(operator, condition_values)
      case operator
      when "any_of"
        { lists: { "$in" => condition_values } }
      when "none_of"
        { lists: { "$nin" => condition_values } }
      when "start_with"
        { lists: { "$in" => condition_values.map { |str| /^#{::Regexp.escape(str)}/ } } }
      when "end_with"
        { lists: { "$in" => condition_values.map { |str| /#{::Regexp.escape(str)}$/ } } }
      end
    end
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:lists)
        self.lists = value
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("lists")}: #{lists.join(",")}" if lists.present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    self.lists = value.to_s.split("\n").map { |v| v.strip }.compact
  end

  def export_csv_cell
    lists.join("\n")
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & lists).present?
  end

  private

  def text_blank?
    lists.all? { |list| list.blank? }
  end

  def validate_value
    return if column.blank? || skip_required?

    if column.required? && text_blank?
      self.errors.add(:lists, :blank)
    end

    return if text_blank?

    if column.max_length.present? && column.max_length > 0
      if lists.any?{ |list| list[:text].length > column.max_length }
        self.errors.add(:list, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    return '' if text_blank?

    li = lists.map { |list| ApplicationController.helpers.sanitize(list) }.
      map { |list| ApplicationController.helpers.content_tag(:li, list) }.
      join("\n")
    ApplicationController.helpers.content_tag(column.list_type.to_sym, li.html_safe)
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.lists %})
      h << %(  <{{ value.list_type }}>)
      h << %(    {% for item in value.lists %})
      h << %(      <li>{{ item | sanitize }}</li>)
      h << %(    {% endfor %})
      h << %(  </{{ value.list_type }}>)
      h << %({% endif %})
      h.join("\n")
    end
  end
end
