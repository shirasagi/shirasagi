module Faq::Addon
  module Search
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      belongs_to :search_node, class_name: "Faq::Node::Search"
      permit_params :search_node_id
    end
  end
end
