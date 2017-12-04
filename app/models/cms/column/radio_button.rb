class Cms::Column::RadioButton < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  def serialize_value(value)
    Cms::Column::Value::RadioButton.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value
    )
  end
end
