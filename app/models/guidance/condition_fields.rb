module Guidance::ConditionFields
  extend ActiveSupport::Concern

  included do
    field :condition_and, type: SS::Extensions::Lines
    field :condition_or1, type: SS::Extensions::Lines
    field :condition_or2, type: SS::Extensions::Lines
    field :condition_or3, type: SS::Extensions::Lines

    permit_params :condition_and, :condition_or1, :condition_or2, :condition_or3
  end

  def complement_condition_and
    complement_condition(condition_and)
  end

  def complement_condition_or1
    complement_condition(condition_or1)
  end

  def complement_condition_or2
    complement_condition(condition_or2)
  end

  def complement_condition_or3
    complement_condition(condition_or3)
  end

  def complement_condition(values)
    values.reject(&:blank?).map do |value|
      value.match?(/:[YN]\z/) ? value : "#{value}:Y"
    end
  end
end
