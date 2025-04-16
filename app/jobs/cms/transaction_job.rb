class Cms::TransactionJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  queue_as :transaction

  self.task_class = Cms::Task
  self.task_name = "cms:transaction"

  def perform(opts = {})
    item = Cms::Transaction::Plan.find(opts[:plan_id])
    task.log item.name
    task.log ""

    item.units.each do |unit|
      unit.site = site
      unit.task = task
      unit.execute
    end
  end

  private

  def task_cond
    { site_id: site_id, name: self.class.task_name }
  end
end
