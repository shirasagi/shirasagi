class Cms::Column::Select < Cms::Column::Base
  include Cms::Addon::Column::SelectLike

  field :place_holder, type: String

  def serialize_value(value)
    Cms::Column::Value::Select.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value
    )
  end
end
