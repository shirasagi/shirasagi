class Cms::Column::Value::CheckBox < Cms::Column::Value::Base
  field :values, type: SS::Extensions::Words

  permit_values values: []

  liquidize do
    export :value
    export :values
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
