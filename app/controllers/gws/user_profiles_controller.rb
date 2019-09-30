class Gws::UserProfilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/user_settings/navi"
  menu_view false

  model Gws::User

  def set_item
    @item = @cur_user
  end

  def show
    respond_to do |format|
      format.html { render }
      format.json do
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

        if presence = @cur_user.user_presence(@cur_site)
          data[:user][:presence_state] = presence.state
          data[:user][:presence_state_label] = presence.label(:state)
          data[:user][:presence_state_style] = presence.state_style
          data[:user][:presence_plan] = presence.plan
          data[:user][:presence_memo] = presence.memo
        end

        data[:user][:password] = nil
        render json: data.to_json
      end
    end
  end
end
