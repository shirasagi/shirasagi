class Gws::ReloadSiteUsageJob < Gws::ApplicationJob
  include Job::Gws::TaskFilter

  self.task_name = "gws:site_usage"

  def perform
    # 権限/ロールが存在しない場合、グループウェアを利用していないとみなす
    return if Gws::Role.site(site).empty?
    site.reload_usage!
  end
end
