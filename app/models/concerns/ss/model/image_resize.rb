module SS::Model::ImageResize
  extend ActiveSupport::Concern
  extend SS::Translation
  include SS::Model::MaxFileSize

  included do
    field :max_width, type: Integer
    field :max_height, type: Integer
    field :quality, type: Integer

    permit_params :max_width, :max_height, :quality

    validates :max_width, presence: true
    validates :max_height, presence: true
    validates :quality, numericality: {
      only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    }
  end

  module ClassMethods
    def min_attributes
      keys = %w(size max_width max_height quality)
      values = {}
      keys.each do |key|
        values[key] = []
      end
      criteria.each do |item|
        keys.each do |key|
          values[key] << item.send(key)
        end
      end
      keys.each do |key|
        values[key] = values[key].reject(&:blank?).min
      end
      values
    end
  end
end
