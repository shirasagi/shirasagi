class Sns::UserAccountsController < ApplicationController
  include Sns::UserFilter
  include SS::CrudFilter

  model SS::User

  # menu_view "ss/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("sns.account"), params.include?(:user) ? sns_user_account_path : sns_cur_user_account_path]
  end

  def permit_fields
    [ :name, :kana, :email, :tel, :tel_ext ]
  end

  def get_params
    para = super
    para.delete(:password) if para[:password].blank?
    para
  end

  def set_item
    @item = @sns_user
  end

  public

  def edit_password
    raise "404" if @sns_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @sns_user, self_edit: true)
    render
  end

  def update_password
    raise "404" if @sns_user.type_sso?

    @model = SS::PasswordUpdateService
    @item = SS::PasswordUpdateService.new(cur_user: @sns_user, self_edit: true)
    @item.attributes = params.require(:item).permit(:old_password, :new_password, :new_password_again)
    @item.in_updated = params[:_updated].to_s
    render_update @item.update_password, render: { template: "edit_password" }
  end
end
