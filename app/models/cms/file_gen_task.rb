class Cms::FileGenTask
  include SS::Model::Task
  include SS::Model::FileGenTask

  belongs_to :node, class_name: "Cms::Node"

  validates :site_id, presence: true
end
