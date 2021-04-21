class Gws::Task
  include SS::Model::Task

  belongs_to :group, class_name: 'Gws::Group'

  class << self
    # override site scope
    def site(site)
      where(group_id: site.id)
    end
  end
end
