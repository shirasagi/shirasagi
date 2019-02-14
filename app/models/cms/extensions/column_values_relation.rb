module Cms::Extensions::ColumnValuesRelation
  extend ActiveSupport::Concern

  class LiquidExports < SS::Liquidization::LiquidExportsBase
    def key?(name)
      find_value(name).present?
    end

    def [](method_or_key)
      find_value(method_or_key) || super
    end

    def find_value(id_or_name)
      if id_or_name.is_a?(Integer)
        @delegatee[id_or_name]
      else
        @delegatee.find { |val| val.id.to_s == id_or_name || val.name == id_or_name }
      end
    end

    delegate :each, to: :@delegatee
    delegate :fetch, to: :@delegatee
  end

  def to_liquid
    LiquidExports.new(self.order_by(order: 1, name: 1).to_a.reject { |value| value.class == Cms::Column::Value::Base })
  end

  def move_up(value_id)
    copy = Array(self.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == value_id }
    if index && index > 0
      copy[index - 1], copy[index] = copy[index], copy[index - 1]
    end
    copy.each_with_index { |value, index| value.order = index }
  end

  def move_down(value_id)
    copy = Array(self.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == value_id }
    if index && index < copy.length - 1
      copy[index], copy[index + 1] = copy[index + 1], copy[index]
    end
    copy.each_with_index { |value, index| value.order = index }
  end

  def move_at(source_id, destination_index)
    copy = Array(self.order_by(order: 1, name: 1).to_a)
    source_index = copy.index { |value| value.id == source_id }
    return if !source_index || source_index == destination_index

    destination_index = 0 if destination_index < 0
    destination_index = -1 if destination_index >= copy.length

    copy.insert(destination_index, copy.delete_at(source_index))
    copy.each_with_index { |value, index| value.order = index }
  end
end
