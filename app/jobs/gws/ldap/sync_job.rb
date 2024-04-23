class Gws::Ldap::SyncJob < Gws::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Gws::Ldap::SyncTask
  self.task_name = Gws::Ldap::SyncTask::TASK_NAME

  def perform
    raise NotImplementedError
  end
end
