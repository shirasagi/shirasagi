class Cms::Column::SelectPage < Cms::Column::Base
  embeds_ids :nodes, class_name: "Cms::Node"
  permit_params node_ids: []
  validate :validate_nodes

  def validate_nodes
    errors.add(:node_ids, :blank) if nodes.blank?
  end
end
