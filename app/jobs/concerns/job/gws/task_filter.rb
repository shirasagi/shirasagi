module Job::Gws::TaskFilter
  extend ActiveSupport::Concern
  include Job::SS::TaskFilter

  included do
    self.task_class = Gws::Task
  end

  private

  def task_cond
    { name: self.class.task_name, group_id: site_id, :site_id.exists => false }
  end
end
