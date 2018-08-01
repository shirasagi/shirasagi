module Gws::Presence::UserFilter
  extend ActiveSupport::Concern

  included do
    model Gws::User

    menu_view "gws/presence/main/menu"
    navi_view "gws/presence/main/navi"

    before_action :deny_with_auth
    before_action :set_editable_users
    before_action :set_manageable
  end

  private

  def deny_with_auth
    raise "403" unless Gws::UserPresence.allowed?(:use, @cur_user, site: @cur_site)
  end

  def set_editable_users
    @editable_users = [@cur_user]
    @editable_users += @cur_user.presence_title_manageable_users
    @editable_user_ids = @editable_users.map(&:id)
  end

  def set_manageable
    @manageable = false

    if Gws::UserPresence.allowed?(:manage_all, @cur_user, site: @cur_site)
      @manageable = true
    end
    if Gws::UserPresence.allowed?(:manage_private, @cur_user, site: @cur_site)
      @manageable = true if @group && (@group.id == @cur_user.gws_default_group.id)
    end
    if Gws::UserPresence.allowed?(:manage_custom_group, @cur_user, site: @cur_site)
      @manageable = true if @custom_group
    end
  end
end
