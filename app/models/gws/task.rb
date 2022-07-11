class Gws::Task
  include SS::Model::Task

  belongs_to :group, class_name: 'Gws::Group'

  class << self
    # override site scope
    def site(site)
      where(group_id: site.id)
    end

    def find_or_create_for_model(item, site: nil)
      task_name = "#{item.collection_name}:#{item.id}"
      self.all.reorder(id: 1).find_or_create_by(group_id: site.try(:id), name: task_name)
    end
  end
end
