class Chorg::EntityLogCache
  include SS::Document

  belongs_to :task, class_name: "Chorg::Task"
  field :logs, type: Array, default: []
  field :sites, type: Hash, default: {}

  validates :task_id, presence: true
end
