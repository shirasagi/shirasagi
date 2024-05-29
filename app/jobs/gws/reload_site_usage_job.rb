class Gws::ReloadSiteUsageJob < Gws::ApplicationJob
  def perform
    return if Gws::Role.site(site).empty?
    site.reload_usage!
  end
end
