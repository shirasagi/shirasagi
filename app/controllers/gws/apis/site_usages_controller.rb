class Gws::Apis::SiteUsagesController < ApplicationController
  include Gws::ApiFilter
  include Gws::BaseFilter

  before_action :check_permission

  private

  def check_permission
    raise "403" unless Gws::Group.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def reload
    Gws::ReloadSiteUsageJob.bind(site_id: @cur_site).perform_now
    @cur_site.reload
    render
  end
end
