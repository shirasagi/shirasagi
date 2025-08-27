module Cms::Addon
  module FormSearch
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :column_name, type: String
      field :column_kind, type: String

      belongs_to :search_node, class_name: "Cms::Node::FormSearch"

      permit_params :column_name, :column_kind, :search_node_id
    end

    def search_node_options
      Cms::Node::FormSearch.site(@cur_site).map { |node| [node.name, node.id] }
    end

    def column_kind_options
      %w(any_of start_with end_with all).map { |v| [ I18n.t("cms.options.column_kind.#{v}"), v ] }
    end
  end
end
