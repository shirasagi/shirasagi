class Gws::Column::UrlField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/url_field", model_class: self)
    end
  end

  def serialize_value(value)
    Gws::Column::Value::UrlField.new(
      column_id: self.id, name: self.name, order: self.order, value: value, text_index: value
    )
  end
end
