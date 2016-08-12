class Cms::CopyNodesTask
  include SS::Model::Task

  field :target_node_name, type: String
  belongs_to :node, class_name: "Cms::Node"

  permit_params :target_node_name

  validates :target_node_name, presence: true

  validate :validate_node_name, if: ->{ target_node_name.present? }

  private
    def validate_node_name
      parent_node_name = target_node_name.match(/(.*\/)*(.+)/)[1]
      if Cms::Node.where(filename: target_node_name).exists?
        errors.add :target_node_name, :duplicate
      elsif !parent_node_name.nil? && !Cms::Node.where(filename: parent_node_name.gsub(/\/$/, "")).exists?
        errors.add :target_node_name, :not_found_parent_nodes, name: parent_node_name.gsub(/\/$/, "")
      end
    end
end
