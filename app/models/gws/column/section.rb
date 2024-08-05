class Gws::Column::Section < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  def section_id
    "section-#{id}"
  end

  def default_value
    name
  end

  def serialize_value(value)
    Gws::Column::Value::TextField.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
