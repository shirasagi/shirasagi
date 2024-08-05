class Gws::Column::Title < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  field :title, type: String
  field :explanation, type: String

  permit_params :title, :explanation

  def default_value
    title || explanation || self.class.model_name.human
  end

  def serialize_value(value)
    Gws::Column::Value::TextField.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
