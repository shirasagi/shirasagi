module Cms::Addon::SiteSearch
  module Category
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :site_search_categories, class_name: "Category::Node::Base"
      permit_params site_search_category_ids: []
      define_method(:site_search_categories) do
        items = ::Category::Node::Base.in(id: site_search_category_ids).to_a
        site_search_category_ids.map { |id| items.find { |item| item.id == id } }
      end
    end
  end
end
