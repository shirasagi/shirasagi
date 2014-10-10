class Sns::User::AccountsController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter

  before_action :require_self

  model SS::User

  menu_view "ss/crud/resource_menu"

  private
    def set_crumbs
      @crumbs << [:"sns.account", sns_user_account_path]
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
