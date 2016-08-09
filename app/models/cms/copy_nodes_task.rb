class Cms::CopyNodesTask
  include SS::Model::Task

  field :target_node_name, type: String
  belongs_to :node, class_name: "Cms::Node"

  permit_params :target_node_name

  validates :target_node_name, presence: true
end
