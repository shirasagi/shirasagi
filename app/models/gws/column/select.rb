class Gws::Column::Select < Gws::Column::Base
  include Gws::Addon::Column::SelectLike

  field :place_holder, type: String

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/select", model_class: self)
    end
  end

  def serialize_value(value)
    Gws::Column::Value::Select.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
