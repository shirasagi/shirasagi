class Gws::Column::Title < Gws::Column::Base
  include Gws::Column::TextLike

  field :title, type: String
  field :explanation, type: String

  permit_params :title, :explanation

  before_save :set_required_optional

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/title", model_class: self)
    end
  end

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
