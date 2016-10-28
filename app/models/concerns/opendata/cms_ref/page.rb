module Opendata::CmsRef::Page
  extend ActiveSupport::Concern

  included do
    field :assoc_site_id, type: Integer
    field :assoc_node_id, type: Integer
    field :assoc_page_id, type: Integer

    scope :and_associated_node, ->(node) { where(assoc_site_id: node.site_id, assoc_node_id: node.id) }
    scope :and_associated_page, ->(page) do
      where(assoc_site_id: page.site_id, assoc_node_id: page.parent.id, assoc_page_id: page.id)
    end
    scope :and_resource_associated_page, ->(page) do
      where(resources: { '$elemMatch' => { assoc_site_id: page.site_id, assoc_node_id: page.parent.id, assoc_page_id: page.id } })
    end
  end

  def assoc_site
    if assoc_site_id.present?
      Cms::Site.find(assoc_site_id) rescue nil
    end
  end

  def assoc_node
    if assoc_node_id.present?
      Cms::Node.find(assoc_node_id) rescue nil
    end
  end

  def assoc_page
    if assoc_page_id.present?
      Cms::Page.find(assoc_page_id) rescue nil
    end
  end
end
