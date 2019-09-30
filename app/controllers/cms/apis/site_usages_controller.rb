class Cms::Apis::SiteUsagesController < ApplicationController
  include Cms::ApiFilter

  before_action :check_permission

  private

  def check_permission
    raise "403" unless Cms::Site.allowed?(:edit, @cur_user, site: @cur_site)
  end

  public

  def reload
    @cur_site.reload_usage!
    render
  end
end
