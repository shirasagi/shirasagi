class Gws::Column::RadioButton < Gws::Column::Base
  include Gws::Addon::Column::SelectLike

  def serialize_value(value)
    Gws::Column::Value::RadioButton.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
