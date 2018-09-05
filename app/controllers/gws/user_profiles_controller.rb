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
        imap_setting = @cur_user.imap_settings[index]
        if imap_setting
          imap_setting = imap_setting.imap_settings(@cur_user.imap_default_settings)
        else
          imap_setting = @cur_user.imap_default_settings
        end

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
