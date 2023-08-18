module Cms::Addon
  module Tabs
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    attr_accessor :cur_date

    included do
      self.default_limit = 8
    end
  end
end
