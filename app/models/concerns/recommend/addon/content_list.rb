module Recommend::Addon
  module ContentList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :exclude_paths, type: SS::Extensions::Lines
      permit_params :exclude_paths
    end

    def limit
      value = self[:limit].to_i
      (value < 1 || 50 < value) ? 5 : value
    end
  end
end
