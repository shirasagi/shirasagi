module Cms::Addon::Column::TextLike
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :max_length, type: Integer
    field :place_holder, type: String
    field :additional_attr, type: String, default: ''

    permit_params :max_length, :place_holder, :additional_attr

    validates :max_length, numericality: { only_integer: true, greater_than_or_equal_to: 0, allow_blank: true }
  end

  def additional_attr_to_h
    additional_attr.scan(/\S+?=".+?"/m).
      map { |s| s.split(/=/).size == 2 ? s.delete('"').split(/=/) : nil }.
      compact.to_h
  end

  def form_options
    options = additional_attr_to_h
    options['maxlength'] = max_length if max_length.present?
    options['placeholder'] = place_holder if place_holder.present?
    options
  end
end
