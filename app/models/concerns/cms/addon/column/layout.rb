module Cms::Addon::Column::Layout
  extend ActiveSupport::Concern
  extend SS::Addon

  included do
    field :layout, type: String
    permit_params :layout
    validates :layout, liquid_format: true
  end
end
