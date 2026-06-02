class Cms::Column::Value::Headline < Cms::Column::Value::Base
  ANCHOR_FORMAT = /\A[A-Za-z0-9_-]+\z/

  field :head, type: String
  field :text, type: String, metadata: { syntax_check: { value: true } }
  field :anchor, type: String

  permit_values :head, :text, :anchor

  liquidize do
    export :head
    export :text
    export :anchor
    export as: :anchor_id do
      resolved_anchor
    end
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
    self.head ||= column&.effective_min_headline_level || 'h1'
  end

  def export_csv_cell
    text
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & [text]).present?
  end

  # Resolves the anchor id used both by the headline output (id="...") and by the
  # table-of-contents block (href="#..."). Both sides call this same method so that
  # the emitted id and the link target always match.
  #
  # - When the editor entered an anchor, it is sanitized to [A-Za-z0-9_-] and used.
  # - When it is blank, a deterministic "headline-N" fallback is used, where N is the
  #   1-based position of this value among the Headline values in the same page
  #   (ordered by +order+).
  def resolved_anchor
    sanitized = sanitize_anchor(anchor)
    return sanitized if sanitized.present?

    "headline-#{headline_index + 1}"
  end

  private

  def sanitize_anchor(value)
    return "" if value.blank?
    value.gsub(/[^A-Za-z0-9_-]/, "")
  end

  def sibling_headlines
    return [] if _parent.blank?

    _parent.column_values
      .select { |v| v.is_a?(Cms::Column::Value::Headline) }
      .sort_by { |v| [v.order.to_i, v.id.to_s] }
  end

  def headline_index
    siblings = sibling_headlines
    siblings.index { |v| v.id == id } || siblings.length
  end

  def validate_value
    return if column.blank?

    if column.required? && head.blank?
      self.errors.add(:head, :blank) unless skip_required?
    end

    if column.required? && text.blank?
      self.errors.add(:text, :blank) unless skip_required?
    end

    if head.present? && column.headline_list.values.exclude?(head)
      self.errors.add(:head, :inclusion, value: head)
    end

    validate_anchor

    return if text.blank?

    if column.max_length.present? && column.max_length > 0
      if text.length > column.max_length
        self.errors.add(:text, :too_long, count: column.max_length)
      end
    end
  end

  def validate_anchor
    return if anchor.blank?

    unless anchor.match?(ANCHOR_FORMAT)
      self.errors.add(:anchor, :invalid)
      return
    end

    if duplicate_anchor?
      self.errors.add(:anchor, :taken)
    end
  end

  def duplicate_anchor?
    return false if _parent.blank?

    _parent.column_values.any? do |v|
      next false if v.id == id
      next false unless v.is_a?(Cms::Column::Value::Headline)

      v.anchor.present? && v.anchor == anchor
    end
  end

  def to_default_html
    return '' if text.blank?
    return '' if head.blank?

    escaped = ApplicationController.helpers.sanitize(text)
    options = {}
    options[:id] = resolved_anchor if column&.try(:anchor_enabled?)
    ApplicationController.helpers.content_tag(head.to_sym, escaped, options)
  end

  class << self
    def form_example_layout
      h = []
      h << %({% if value.text %})
      h << %(  {%- if value.anchor_id != blank -%})
      h << %(  <{{ value.head }} id="{{ value.anchor_id }}">{{ value.text | sanitize }}</{{ value.head }}>)
      h << %(  {%- else -%})
      h << %(  <{{ value.head }}>{{ value.text | sanitize }}</{{ value.head }}>)
      h << %(  {%- endif -%})
      h << %({% endif %})
      h.join("\n")
    end
  end
end
