class Gws::Column::TextField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  field :input_type, type: String
  permit_params :input_type

  validates :input_type, presence: true, inclusion: { in: %w(text email tel), allow_blank: true }

  class << self
    def as_plugin
      @plugin ||= Gws::Plugin.new(plugin_type: "column", path: "gws/text_field", model_class: self)
    end

    def default_attributes
      attributes = super
      attributes[:input_type] = "text"
      attributes
    end
  end

  def input_type_options
    %w(text email tel).map do |v|
      [ I18n.t("gws/column.options.column_input_type.#{v}"), v ]
    end
  end

  def form_options
    options = super
    options['type'] = input_type
    options
  end

  def serialize_value(value)
    Gws::Column::Value::TextField.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
