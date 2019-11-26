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
    @cur_site.reload_usage!
    render
  end
end
