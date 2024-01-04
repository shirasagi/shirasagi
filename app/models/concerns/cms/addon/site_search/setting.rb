module Cms::Addon::SiteSearch
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :site_search_type, type: String, default: 'page'
      embeds_ids :st_article_nodes, class_name: "Article::Node::Page"
      permit_params :site_search_type, st_article_node_ids: []
    end

    def site_search_type_options
      %w(page file all).collect { |k| [I18n.t("cms.options.site_search_type.#{k}"), k] }
    end
  end
end
