module Cms::Addon
  module Tabs
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      self.default_limit = 1
    end
  end
end
