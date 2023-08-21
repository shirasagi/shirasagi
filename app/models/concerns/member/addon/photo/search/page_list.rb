module Member::Addon::Photo::Search
  module PageList
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

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
  end
end
