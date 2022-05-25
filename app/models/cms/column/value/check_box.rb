class Cms::Column::Value::CheckBox < Cms::Column::Value::Base
  field :values, type: SS::Extensions::Words

  permit_values values: []

  liquidize do
    export :value
    export :values
  end

  class << self
    def build_mongo_query(operator, condition_values)
      case operator
      when "any_of"
        { values: { "$in" => condition_values } }
      when "none_of"
        { values: { "$nin" => condition_values } }
      when "start_with"
        { values: { "$in" => condition_values.map { |str| /^#{::Regexp.escape(str)}/ } } }
      when "end_with"
        { values: { "$in" => condition_values.map { |str| /#{::Regexp.escape(str)}$/ } } }
      end
    end
  end

  def value
    values.join(', ')
  end

  def import_csv(values)
    super

    values.map do |name, value|
      case name
      when self.class.t(:values)
        self.values = value.to_s.split(",").map(&:strip)
      end
    end
  end

  def history_summary
    h = []
    h << "#{t("values")}: #{values.join(",")}" if values.present?
    h << "#{t("alignment")}: #{I18n.t("cms.options.alignment.#{alignment}")}"
    h.join(",")
  end

  def import_csv_cell(value)
    self.values = value.to_s.split("\n").map { |v| v.strip }.compact
  end

  def export_csv_cell
    values.join("\n")
  end

  def search_values(values)
    return false unless values.instance_of?(Array)
    (values & self.values).present?
  end

  private

  def validate_value
    return if column.blank?

    if column.required? && values.blank?
      self.errors.add(:values, :blank)
    end

    return if values.blank?

    diff = values - column.select_options
    if diff.present?
      self.errors.add(:values, :inclusion, value: diff.join(', '))
    end
  end
end
