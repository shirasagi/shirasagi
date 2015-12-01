class Sns::UserAccountsController < ApplicationController
  include Sns::UserFilter
  include Sns::CrudFilter

  model SS::User

  menu_view "ss/crud/resource_menu"

  private
    def set_crumbs
      @crumbs << [:"sns.account", sns_user_account_path]
    end

    def permit_fields
      [:name, :email, :in_password]
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
