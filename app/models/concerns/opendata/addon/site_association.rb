module Opendata::Addon::SiteAssociation
  extend SS::Addon
  extend ActiveSupport::Concern

  included do
    belongs_to :assoc_site, class_name: "Cms::Site"
    belongs_to :assoc_node, class_name: "Cms::Node"
    belongs_to :assoc_page, class_name: "Cms::Page"
    belongs_to :assoc_file, class_name: "SS::File"

    scope :and_associated_node, ->(node) { where(assoc_site_id: node.site_id, assoc_node_id: node.id) }
    scope :and_associated_page, ->(page) { where(assoc_site_id: page.site_id, assoc_node_id: page.parent.id, assoc_page_id: page.id) }
    scope :and_associated_file, ->(file) { where(assoc_file_id: file.id) }
  end
end
