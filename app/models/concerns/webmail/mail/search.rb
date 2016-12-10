module Webmail::Mail::Search
  extend ActiveSupport::Concern

  included do
    scope :imap_search, ->(params) {
      criteria = where({})
      return criteria if params.blank?

      filters = []

      [:from, :to, :subject, :text].each do |key|
        next if params[key].blank?
        filters << key.to_s.upcase
        filters << params[key].dup.force_encoding('ASCII-8BIT')
      end

      [:since, :before, :sentsince, :sentbefore].each do |key|
        next if params[key].blank?
        filters << key.to_s.upcase
        filters << Date.parse(params[key]).strftime('%e-%b-%Y')
      end

      criteria = criteria.where(search: filters) if filters.present?
      criteria
    }
  end

  class_methods do
    def imap_search_label(params)
      return nil if params.blank?

      h = []
      params.each do |key, val|
        next if val.blank?
        h << t(key) + ": #{val}"
      end

      h.present? ? h.join(', ') : nil
    end
  end
end
