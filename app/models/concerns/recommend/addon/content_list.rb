module Recommend::Addon
  module ContentList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def limit
      value = self[:limit].to_i
      (value < 1 || 100 < value) ? 5 : value
    end
  end
end
