class Gws::Column::CheckBox < Gws::Column::Base
  include Gws::Addon::Column::SelectLike
  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/check_box", model_class: self)
    end
  end

  def serialize_value(values)
    ret = Gws::Column::Value::CheckBox.new(
      column_id: self.id, name: self.name, order: self.order,
      values: values
    )
    ret.text_index = ret.value
    ret
  end
end
