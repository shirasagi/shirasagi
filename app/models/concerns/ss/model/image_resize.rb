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
    def intersection(lhs, rhs)
      return rhs.dup if lhs.nil?
      return lhs.dup if rhs.nil?

      intersected_attr = {}
      %w(max_width max_height size quality).each do |attr|
        lhs_value = lhs.attributes[attr]
        rhs_value = rhs.attributes[attr]
        if lhs_value.nil?
          intersected_attr[attr] = rhs_value
        elsif rhs_value.nil?
          intersected_attr[attr] = lhs_value
        else
          diff = lhs_value <=> rhs_value
          if diff <= 0
            intersected_attr[attr] = lhs_value
          else
            intersected_attr[attr] = rhs_value
          end
        end
      end

      new(intersected_attr)
    end
  end
end
