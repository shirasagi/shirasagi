class Cms::Column::SelectPage < Cms::Column::Base
  field :place_holder, type: String
  belongs_to :node, class_name: "Cms::Node"
  permit_params :node_id

  def select_options
    return [] if node.nil?
    return [] if !node.respond_to?(:sort_hash)
    Article::Page.public_list(site: node.site, node: node).order_by(node.sort_hash).pluck(:name, :id)
  end
end
