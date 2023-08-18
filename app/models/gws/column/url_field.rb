class Gws::Column::UrlField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  def serialize_value(value)
    Gws::Column::Value::UrlField.new(
      column_id: self.id, name: self.name, order: self.order, value: value, text_index: value
    )
  end
end
