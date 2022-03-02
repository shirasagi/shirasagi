module Article::Addon
  module MapSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :map_search_options, type: Article::Extensions::MapSearchOptions, default: []
      belongs_to :form, class_name: "Cms::Form"
      belongs_to :node, class_name: "Article::Node::Page"
      permit_params :form_id, :node_id, map_search_options: [:name, :values]

      validates :form_id, presence: true
    end

    def form_options
      Cms::Form.where(site_id: @cur_site.id, sub_type: 'static').map { |item| [item.name, item.id] }
    end

    def node_options
      Article::Node::Page.where(site_id: @cur_site.id).map { |item| [item.name, item.id] }
    end

    def pages
      pages = Article::Page.where(form_id: form_id)
      pages = pages.node(node) if node_id
      pages
    end

    def condition_hash
      {}
    end
  end
end
