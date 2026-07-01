class Gws::UserMessageDisplaySettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::UserSettingFilter

  before_action :check_permission

  private

  def check_permission
    raise "404" unless @cur_site.menu_memo_visible?
    raise "403" unless Gws.module_usable?(:memo, @cur_site, @cur_user)
  end

  def permit_fields
    [ :message_list_column_order ]
  end
end
