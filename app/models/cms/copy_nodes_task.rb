class Cms::CopyNodesTask
  include SS::Model::Task

  field :target_node_name, type: String
  field :target_node_filename, type: String
  belongs_to :node, class_name: "Cms::Node"

  permit_params :target_node_name, :target_node_filename

  validates :target_node_name, presence: true
  validates :target_node_filename, presence: true
  validate :validate_node_filename

  private

  def validate_node_filename
    return if target_node_filename.blank?

    dirname = target_node_filename.match(/(.*\/)*(.+)/)[1]
    if Cms::Node.where(filename: target_node_filename, site_id: self.site_id).exists?
      errors.add :target_node_filename, :duplicate
    elsif dirname.present? && !Cms::Node.where(filename: dirname.gsub(/\/$/, ""), site_id: self.site_id).exists?
      errors.add :target_node_filename, :not_found_parent_nodes, name: dirname.gsub(/\/$/, "")
    end
  end
end
