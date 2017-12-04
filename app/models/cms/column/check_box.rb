class Cms::Column::CheckBox < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  def serialize_value(values)
    Cms::Column::Value::CheckBox.new(
      column_id: self.id, name: self.name, order: self.order,
      values: values
    )
  end
end
