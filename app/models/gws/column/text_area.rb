class Gws::Column::TextArea < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/text_area", model_class: self)
    end
  end

  def serialize_value(value)
    Gws::Column::Value::TextArea.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
