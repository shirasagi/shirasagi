class Gws::Task
  include SS::Model::Task

  belongs_to :group, class_name: 'Gws::Group'

  # override site scope
  scope :site, ->(site) { where(group_id: site.id) }
end
