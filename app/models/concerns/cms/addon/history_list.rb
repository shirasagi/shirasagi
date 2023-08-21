module Cms::Addon
  module HistoryList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      self.default_limit = 5
      self.use_conditions = false
      self.use_no_items_display = false
      self.use_new_days = false
      self.use_sort = false
      self.use_substitute_html = false
    end

    def limit
      value = self[:limit].to_i
      (value < 1 || value > 50) ? 5 : value
    end

    def list_identity
      key = loop_format_liquid? ? "#{id}_#{loop_liquid}" : "#{id}_#{upper_html}_#{loop_html}_#{lower_html}"
      Digest::MD5.hexdigest(key)
    end
  end
end
