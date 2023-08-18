module Facility::Addon
  module Notice
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    def notice_limit
      5
    end

    def sort_options
      %w(name filename created updated_desc released_desc order order_desc).map do |k|
        [
          I18n.t("cms.sort_options.#{k}.title"),
          k.sub("_desc", " -1"),
          "data-description" => I18n.t("cms.sort_options.#{k}.description", default: nil)
        ]
      end
    end

    def sort_hash
      return { released: -1 } if sort.blank?
      { sort.sub(/ .*/, "") => (/-1$/.match?(sort) ? -1 : 1) }
    end

    def notices
      Facility::Notice.site(site).
        where(filename: /\A#{::Regexp.escape(filename)}\//, depth: depth + 1).
        order_by(sort_hash)
    end
  end
end
