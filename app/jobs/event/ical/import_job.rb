class Event::Ical::ImportJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  queue_as :external

  self.task_class = Cms::Task
  self.task_name = "event:import_pages"
  self.controller = Event::Agents::Tasks::Page::PagesController
  self.action = :import_ical

  class << self
    def perform_jobs(site, user = nil)
      Event::Node::Page.site(site).and_public.each do |node|
        perform_job(site, node, user)
      end
    end

    def perform_job(site, node, user = nil)
      return if node.try(:ical_refresh_disabled?)

      if node.try(:ical_refresh_auto?)
        bind(site_id: site.id, node_id: node.id, user_id: user.present? ? user.id : nil).perform_now
      else
        Rails.logger.info("node `#{node.filename}` is prohibited to update")
      end
    end
  end

  def perform(*args)
    task.process self.class.controller, self.class.action, { site: site, node: node, user: user, args: args }
  end

  def task_cond
    cond = { name: self.class.task_name }
    cond[:site_id] = site_id
    cond[:node_id] = node_id
    cond
  end
end
