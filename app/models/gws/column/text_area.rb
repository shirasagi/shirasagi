class Gws::Column::TextArea < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  def serialize_value(value)
    Gws::Column::Value::TextArea.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value
    )
  end
end
