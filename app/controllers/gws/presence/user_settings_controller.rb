class Gws::Presence::UserSettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  before_action :check_permission

  private

  def check_permission
    raise "404" unless @cur_site.menu_presence_visible?
    raise "403" unless Gws.module_usable?(:presence, @cur_site, @cur_user)
  end

  def set_item
    @item = @cur_user.user_presence(@cur_site)
  end

  def fix_params
    { cur_site: @cur_site, cur_user: @cur_user }
  end

  def permit_fields
    [ :sync_available_state, :sync_unavailable_state, :sync_timecard_state ]
  end

  public

  def update
    @item.attributes = get_params
    render_update @item.update
  end
end
