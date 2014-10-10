class Sns::LoginController < ApplicationController
  include Sns::BaseFilter

  skip_filter :logged_in?, only: [:login]

  navi_view nil

  private
    def get_params
      params.require(:item).permit(:email, :password, :ref)
    end

  public
    def login
      @item = SS::User.new
      @item.email    = params[:email]
      @item.password = params[:password]
      return if !request.post?

      @item.attributes = get_params
      user = SS::User.where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first
      return if !user

      if params[:ref].blank? || [sns_login_path, sns_mypage_path].index(params[:ref])
        return set_user user, session: true, redirect: true
      end

      set_user user, session: true
      render action: :redirect
    end

    def logout
      put_history_log
      unset_user redirect: true
    end
end
