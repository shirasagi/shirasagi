class Gws::Column::DateField < Gws::Column::Base

  field :input_type, type: String
  field :place_holder, type: String
  permit_params :input_type, :place_holder, :html_tag, :html_additional_attr

  class << self
    def default_attributes
      attributes = super
      attributes[:input_type] = "date"
      attributes
    end
  end

  def input_type_options
    %w(date datetime).map do |v|
      [ I18n.t("gws/column.options.date_input_type.#{v}"), v ]
    end
  end

  def form_options
    options = {}
    options['placeholder'] = place_holder if place_holder.present?

    if input_type == "datetime"
      options['class'] = %w(datetime js-datetime)
    else
      options['class'] = %w(date js-date)
    end

    options
  end

  def serialize_value(value)
    ret = Gws::Column::Value::DateField.new(
      column_id: self.id, name: self.name, order: self.order, date: value
    )
    ret.text_index = ret.value
    ret
  end
end
