class Gws::Column::CheckBox < Gws::Column::Base
  include Gws::Addon::Column::SelectLike

  def serialize_value(values)
    ret = Gws::Column::Value::CheckBox.new(
      column_id: self.id, name: self.name, order: self.order,
      values: values
    )
    ret.text_index = ret.value
    ret
  end
end
