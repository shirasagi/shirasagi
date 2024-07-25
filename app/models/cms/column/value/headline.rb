class Cms::Column::Value::Headline < Cms::Column::Value::Base
  field :head, type: String
  field :text, type: String

  permit_values :head, :text

  liquidize do
    export :head
    export :text
  end

  class << self
    def build_mongo_query(operator, condition_values)
      case operator
      when "any_of"
        { text: { "$in" => condition_values } }
      when "none_of"
        { text: { "$nin" => condition_values } }
      when "start_with"
        { text: { "$in" => condition_values.map { |str| /^#{::Regexp.escape(str)}/ } } }
      when "end_with"
        { text: { "$in" => condition_values.map { |str| /#{::Regexp.escape(str)}$/ } } }
      end
    end
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:head)
        self.head = value
      when self.class.t(:text)
        self.text = value
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("head")}: #{head}" if head.present?
    h << "#{t("head")}: #{text}" if text.present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    self.text = value.presence
    self.head ||= 'h1'
  end

  def export_csv_cell
    text
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [text]).present?
  end

  private

  def validate_value
    return if column.blank? || _parent.skip_required?

    if column.required? && head.blank?
      self.errors.add(:head, :blank)
    end

    if column.required? && text.blank?
      self.errors.add(:text, :blank)
    end

    return if text.blank?

    if column.max_length.present? && column.max_length > 0
      if text.length > column.max_length
        self.errors.add(:text, :too_long, count: column.max_length)
      end
    end
  end

  def to_default_html
    return '' if text.blank?
    return '' if head.blank?

    escaped = ApplicationController.helpers.sanitize(text)
    ApplicationController.helpers.content_tag(head.to_sym, escaped)
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.text %})
      h << %(  <{{ value.head }}>{{ value.text | sanitize }}</{{ value.head }}>)
      h << %({% endif %})
      h.join("\n")
    end
  end
end
