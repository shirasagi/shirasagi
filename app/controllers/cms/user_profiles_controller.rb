class Cms::UserProfilesController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/user_profiles/navi"
  menu_view "cms/user_profiles/menu"

  model Cms::User

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
    render
  end

  def edit
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_user_profile)
    render
  end

  def update
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :edit_cms_user_profile)
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.save
  end

  def edit_password
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :edit_password_cms_user_profile)
    raise "404" if @cur_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @cur_user, self_edit: true, site: @cur_site)
    render
  end

  def update_password
    raise '403' unless @cur_user.cms_role_permit_any?(@cur_site, :edit_password_cms_user_profile)
    raise "404" if @cur_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @cur_user, self_edit: true, site: @cur_site)
    @item.attributes = params.require(:item).permit(:old_password, :new_password, :new_password_again)
    @item.in_updated = params[:_updated].to_s
    render_update @item.update_password, render: { template: "edit_password" }
  end
end
