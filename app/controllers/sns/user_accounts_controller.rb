class Sns::UserAccountsController < ApplicationController
  include Sns::UserFilter
  include SS::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  private

  def set_crumbs
    @crumbs << [t("sns.account"), params.include?(:user) ? sns_user_account_path : sns_cur_user_account_path]
  end

  def fix_params
    { self_edit: true }
  end

  def permit_fields
    [:name, :kana, :email, :in_password, :tel, :tel_ext]
  end

  def get_params
    para = super
    para.delete(:password) if para[:password].blank?
    para
  end

  def set_item
    @item = @sns_user
  end
end
