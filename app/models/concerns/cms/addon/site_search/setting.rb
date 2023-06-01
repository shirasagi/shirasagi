module Cms::Addon::SiteSearch
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      embeds_ids :st_article_nodes, class_name: "Article::Node::Page"
      permit_params st_article_node_ids: []
    end

    def site_search_type_options
      %w(page file).collect { |k| [I18n.t("cms.options.site_search_type.#{k}"), k] }
    end
  end
end
