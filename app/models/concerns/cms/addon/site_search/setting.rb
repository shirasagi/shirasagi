module Cms::Addon::SiteSearch
  module Setting
    extend SS::Addon
    extend ActiveSupport::Concern

    included do
      field :link_target, type: String
      field :search_type_state, type: String
      field :article_node_state, type: String
      field :category_state, type: String
      field :organization_state, type: String
      field :site_search_type, type: String
      embeds_ids :st_article_nodes, class_name: "Article::Node::Page"
      permit_params :link_target, :search_type_state,
        :article_node_state, :category_state, :organization_state,
        :site_search_type, st_article_node_ids: []
    end

    def link_target_options
      [
        [I18n.t('cms.options.link_target.self'), ''],
        [I18n.t('cms.options.link_target.blank'), 'blank'],
      ]
    end

    def search_type_state_options
      %w(show hide).collect { |k| [I18n.t("ss.options.state.#{k}"), k == 'show' ? nil : k] }
    end

    def article_node_state_options
      %w(show hide).collect { |k| [I18n.t("ss.options.state.#{k}"), k == 'show' ? nil : k] }
    end

    def category_state_options
      %w(show hide).collect { |k| [I18n.t("ss.options.state.#{k}"), k == 'show' ? nil : k] }
    end

    def organization_state_options
      %w(show hide).collect { |k| [I18n.t("ss.options.state.#{k}"), k == 'show' ? nil : k] }
    end

    def site_search_type_options
      %w(page file all).collect { |k| [I18n.t("cms.options.site_search_type.#{k}"), k] }
    end
  end
end
