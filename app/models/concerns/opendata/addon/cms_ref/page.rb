module Opendata::Addon::CmsRef::Page
  extend SS::Addon
  extend ActiveSupport::Concern
  include Opendata::CmsRef::Page

  included do
    field :assoc_method, type: String, default: 'auto'
    embeds_ids :assoc_sites, class_name: "Cms::Site"
    embeds_ids :assoc_nodes, class_name: "Cms::Node"
    embeds_ids :assoc_pages, class_name: "Cms::Page"
    validates :assoc_method, inclusion: { in: %w(none auto) }

    scope :and_associated_page, ->(page) do
      where(assoc_site_id: page.site_id, assoc_node_id: page.parent.id).where("$and" => [{ "$or" => [ { assoc_page_id: page.id }, { assoc_page_ids: { '$in' => [page.id] } } ] }])
    end
  end

  def assoc_method_options
    %w(none auto).map do |v|
      [ I18n.t("opendata.crawl_update_name.#{v}"), v ]
    end
  end
end
