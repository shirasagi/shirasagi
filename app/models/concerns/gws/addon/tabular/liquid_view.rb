module Gws::Addon::Tabular::LiquidView
  extend ActiveSupport::Concern
  extend SS::Addon

  AVAILABLE_DIRECTIONS = %w(asc desc).freeze

  included do
    field :template_html, type: String
    field :template_style, type: String
    field :orders, type: Array
    field :limit_count, type: Integer, default: ->{ SS.max_items_per_page }
    permit_params :template_html, :template_style, :limit_count, orders: [ :column_id, :direction ]

    before_validation :normalizer_orders

    validates :template_html, liquid_format: true
    validates :limit_count, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 200, allow_blank: true }
  end

  def order_hash
    return {} if orders.blank?

    columns = form.columns.reorder(order: 1, id: 1).to_a
    id_column_map = columns.index_by { |column| column.id.to_s }

    ret = {}
    orders.each do |order_spec|
      order_column_id = order_spec[:column_id]
      order_direction = order_spec[:direction]
      next if order_column_id.blank? || order_direction.blank?
      next unless AVAILABLE_DIRECTIONS.include?(order_direction)

      order_column_id = order_column_id.to_s
      if BSON::ObjectId.legal?(order_column_id)
        column = id_column_map[order_column_id]
        next unless column

        ret[column.store_as_in_file] = order_direction == "asc" ? 1 : -1
      else
        ret[order_column_id] = order_direction == "asc" ? 1 : -1
      end
    end

    ret
  end

  private

  def normalizer_orders
    return if orders.blank?

    self.orders = orders.select do |order|
      next false if order[:column_id].blank?
      next false if order[:direction].blank?
      next false unless AVAILABLE_DIRECTIONS.include?(order[:direction])
      true
    end
  end
end
