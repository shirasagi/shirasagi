module Gws::Addon::Tabular::ListView
  extend ActiveSupport::Concern
  extend SS::Addon

  AVAILABLE_DIRECTIONS = %w(asc desc).freeze

  included do
    embeds_ids :title_columns, class_name: "Gws::Column::Base"
    embeds_ids :meta_columns, class_name: "Gws::Column::Base"
    field :orders, type: Array
    field :limit_count, type: Integer, default: ->{ SS.max_items_per_page }
    field :filters, type: Array
    field :aggregations, type: Array
    permit_params title_column_ids: [], meta_column_ids: [], orders: [ :column_id, :direction ]
    permit_params :limit_count

    before_validation :normalizer_orders

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
