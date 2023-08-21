class Cms::Task
  include SS::Model::Task

  belongs_to :node, class_name: "Cms::Node"

  validates :site_id, presence: true
end
