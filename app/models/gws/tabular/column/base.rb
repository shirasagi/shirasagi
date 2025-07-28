module Gws::Tabular::Column::Base
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    field :index_state, type: String, default: 'none'
    field :unique_state, type: String, default: 'disabled'
    permit_params :index_state, :unique_state
    validates :index_state, presence: true, inclusion: { in: %w(none asc desc), allow_blank: true }
    validates :unique_state, presence: true, inclusion: { in: %w(disabled enabled), allow_blank: true }
  end

  def index_state_options
    %w(none asc desc).map do |v|
      [ I18n.t("gws/tabular.options.order_direction.#{v}"), v ]
    end
  end

  def unique_state_options
    %w(disabled enabled).map do |v|
      [ I18n.t("ss.options.state.#{v}"), v ]
    end
  end

  def store_as_in_file
    "col_#{id}"
  end

  def to_csv_value(_item, db_value, **_options)
    db_value.to_s.presence
  end

  def from_csv_value(_item, csv_value, **_options)
    csv_value
  end

  def read_csv_value(item, locale: nil)
    value = item.read_tabular_value(self)
    to_csv_value(item, value, locale: locale)
  end

  def write_csv_value(item, csv_value, locale: nil)
    field_name = "col_#{id}"
    value = from_csv_value(item, csv_value, locale: locale)

    method_name = item.class.field_name_to_method_name_map[field_name]
    method_name ||= field_name
    item.public_send("#{method_name}=", value)
  end
end
