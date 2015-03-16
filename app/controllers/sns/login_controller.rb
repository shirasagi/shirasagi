class Sns::LoginController < ApplicationController
  include Sns::BaseFilter

  skip_filter :logged_in?, only: [:login]

  navi_view nil

  private
    def get_params
      params.require(:item).permit(:in_group, :email, :password)
    end

  public
    def login
      return if !request.post?

      safe_params = get_params

      in_group = safe_params[:in_group]
      email_or_uid = safe_params[:email]
      password = safe_params[:password]

      @cur_group = SS::Group.or({ id: in_group }, { name: in_group }).first if in_group.present?
      @cur_group = @cur_group.root if @cur_group.present?

      @item = SS::User.authenticate(@cur_group, email_or_uid, password)
      return if !@item

      if params[:ref].blank? || [sns_login_path, sns_mypage_path].index(params[:ref])
        return set_user @item, session: true, redirect: true, password: password
      end

      set_user @item, session: true, password: password
      render action: :redirect
    end

    def logout
      put_history_log
      unset_user redirect: true
    end
end
