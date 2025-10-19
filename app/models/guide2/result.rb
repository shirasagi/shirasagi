class Guide2::Result
  # include Mongoid::Document
  include SS::Document

  field :id, type: Integer
  field :name, type: String
  field :location, type: String
  field :order, type: Integer
  field :conditions, type: Array, default: []
  embedded_in :parent, class_name: "Guide2::Node::Question"

  before_save :set_id
  before_save :remove_blank_condition

  # validates :name, presence: true

  class << self
    def table_fields
      [:name, :location, :order]
    end
  end

  private

  def set_id
    self.id = parent.guide2_results.max(:_id).to_i + 1 if id.blank?
    self.id = self.id.to_i
  end

  def remove_blank_condition
    new_conditions = conditions.map do |data|
      next nil if data[:_id].blank? || data[:value].blank?
      if data[:value].match(/\A[YＹ]/i)
        data[:value] = 'YES'
      elsif data[:value].match(/\A[OＯ]/i)
        data[:value] = 'OR'
      elsif data[:value].match(/\A[NＮ]/i)
        data[:value] = 'NO'
      else
        data[:value] = nil
      end
      data
    end
    self.conditions = new_conditions.reject!(&:blank?)
  end
end
