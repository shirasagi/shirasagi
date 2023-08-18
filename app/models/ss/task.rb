class SS::Task
  include SS::Model::Task

  index(site_id: 1, name: 1)

  class << self
    def find_or_create_for_model(item, site: nil)
      task_name = "#{item.collection_name}:#{item.id}"
      self.all.reorder(id: 1).find_or_create_by(site_id: site.try(:id), name: task_name)
    end
  end
end
