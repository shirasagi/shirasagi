class Cms::Column::SelectPage < Cms::Column::Base
  field :place_holder, type: String
  belongs_to :node, class_name: "Cms::Node"
  permit_params :node_id

  def select_options
    return [] if node.nil?
    Article::Page.public_list(site: node.site, node: node).pluck(:name, :id)
  end
end
