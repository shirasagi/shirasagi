module Opendata::Addon::SiteAssociation
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    belongs_to :assoc_site, class_name: "Cms::Site"
    belongs_to :assoc_node, class_name: "Cms::Node"

    scope :and_associated, ->(node) { where(assoc_site_id: node.site_id, assoc_node_id: node.id) }
  end
end
