class Gws::UserProfilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  menu_view false

  model Gws::User

  def set_item
    @item = @cur_user
  end

  def show
    respond_to do |format|
      format.html { render }
      format.json {
        index = @cur_user.imap_default_index || 0
        user_setting = @cur_user.imap_settings[index]
        base_setting = @cur_user.imap_default_settings
        imap_setting = user_setting ? user_setting.imap_settings(base_setting) : base_setting

        data = {
          authenticity_token: session[:_csrf_token],
          user: @cur_user.attributes,
          group: @cur_group.attributes,
          imap_setting: imap_setting
        }

        data[:user][:password] = nil
        render json: data.to_json
      }
    end
  end
end
