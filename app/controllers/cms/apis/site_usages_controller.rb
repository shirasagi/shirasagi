class Cms::Apis::SiteUsagesController < ApplicationController
  include Cms::ApiFilter

  before_action :check_permission

  private

  def check_permission
    return if @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_body_usages)
    return if Cms::Site.allowed?(:edit, @cur_user, site: @cur_site)

    raise "403"
  end

  public

  def reload
    @cur_site.reload_usage!
    render
  end
end
