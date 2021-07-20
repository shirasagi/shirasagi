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
end
