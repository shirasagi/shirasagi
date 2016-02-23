module Facility::Addon
  module SearchSetting
    extend ActiveSupport::Concern
    extend SS::Addon
    include Cms::Addon::List::Model

    included do
      field :search_html, type: String

      permit_params :search_html
    end

    def sort_hash
      return { filename: 1 } if sort.blank?
      { sort.sub(/ .*/, "") => (sort =~ /-1$/ ? -1 : 1) }
    end
  end
end
