class Gws::Column::DateField < Gws::Column::Base

  field :place_holder, type: String
  permit_params :place_holder, :html_tag, :html_additional_attr

  def form_options
    options = {}
    options['placeholder'] = place_holder if place_holder.present?
    options['class'] = %w(date js-date)
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
