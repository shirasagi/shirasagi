class Gws::UserProfilesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/user_settings/navi"
  menu_view "gws/user_profiles/menu"

  model Gws::User

  private

  def set_crumbs
    @crumbs << [ t("sns.profile"), action: :show ]
  end

  def append_view_paths
    append_view_path "app/views/sns/user_accounts"
    super
  end

  def permit_fields
    [ :name, :kana, :email, :tel, :tel_ext ]
  end

  def set_item
    @item = @cur_user
  end

  public

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

  def edit
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_user_profile)
    render
  end

  def update
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_user_profile)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.save
  end

  def edit_password
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_password_gws_user_profile)
    raise "404" if @cur_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @cur_user, self_edit: true, organization: @cur_site)
    render
  end

  def update_password
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_password_gws_user_profile)
    raise "404" if @cur_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @cur_user, self_edit: true, organization: @cur_site)
    @item.attributes = params.require(:item).permit(:old_password, :new_password, :new_password_again)
    @item.in_updated = params[:_updated].to_s
    render_update @item.update_password, render: { template: "edit_password" }
  end
end
