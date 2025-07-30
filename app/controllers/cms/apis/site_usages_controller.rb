class Cms::Apis::SiteUsagesController < ApplicationController
  include Cms::ApiFilter

  before_action :check_permission

  private

  def check_permission
    raise "403" unless Cms::Site.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def reload
    Cms::ReloadSiteUsageJob.bind(site_id: @cur_site).perform_now
    @cur_site.reload
    render
  end
end
