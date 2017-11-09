class Gws::Column::TextField < Gws::Column::Base
  include Gws::Addon::Column::TextLike

  field :input_type, type: String
  permit_params :input_type

  validates :input_type, presence: true, inclusion: { in: %w(text email search tel url), allow_blank: true }

  def input_type_options
    %w(text email search tel url).map do |v|
      [ I18n.t("gws/column.options.column_input_type.#{v}"), v ]
    end
  end

  def form_options
    options = super
    if input_type == 'date'
      options['class'] = [ options['class'] ].flatten.compact
      options['class'] << 'date'
      options['class'] << 'js-date'
    elsif input_type.present?
      options['type'] = input_type
    end
    options
  end

  def serialize_value(value)
    Gws::Column::Value::TextField.new(
      column_id: self.id, name: self.name, order: self.order,
      value: value, text_index: value
    )
  end
end
