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
    LiquidExports.new(self.order_by(order: 1, name: 1).to_a)
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

  def move_at(value_id, order)
    copy = Array(self.order_by(order: 1, name: 1).to_a)
    index = copy.index { |value| value.id == value_id }

    if index && index != order
      delete_index = index

      insert_index = order
      insert_index = -1 if insert_index < 0
      insert_index = -1 if insert_index >= copy.length
      insert_index -= 1 if delete_index < insert_index

      copy.insert(insert_index, copy.delete_at(delete_index))
    end

    copy.each_with_index { |value, index| value.order = index }
  end
end
