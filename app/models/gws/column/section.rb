class Gws::Column::Section < Gws::Column::Base
  include Gws::Column::TextLike

  before_save :set_required_optional

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/section", model_class: self)
    end
  end

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
