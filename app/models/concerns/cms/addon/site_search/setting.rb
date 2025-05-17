module Cms::Addon::SiteSearch
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :link_target, type: String
      field :site_search_type, type: String
      embeds_ids :st_article_nodes, class_name: "Article::Node::Page"
      permit_params :link_target, :site_search_type, st_article_node_ids: []
    end

    def link_target_options
      [
        [I18n.t('cms.options.link_target.self'), ''],
        [I18n.t('cms.options.link_target.blank'), 'blank'],
      ]
    end

    def site_search_type_options
      # %w(page file all).collect { |k| [I18n.t("cms.options.site_search_type.#{k}"), k] }
      %w(page file).collect { |k| [I18n.t("cms.options.site_search_type.#{k}"), k] }
    end
  end
end
