class Sns::LoginController < ApplicationController
  include Sns::BaseFilter

  skip_filter :logged_in?, only: [:login]
  before_action :set_group

  navi_view nil

  private
    def get_params
      params.require(:item).permit(:email, :password, :ref)
    end

    def set_group
      in_group = params[:group_id] || params[:item].try(:[], :in_group)
      @cur_group = SS::Group.or({ id: in_group }, { name: in_group }).first if in_group.present?
      @cur_group = @cur_group.root if @cur_group.present?
    end

  public
    def login
      @item = SS::User.new
      @item.in_id       = params[:item].try(:[], :in_id)
      @item.password    = params[:item].try(:[], :password)
      return if !request.post?

      @item.attributes = get_params
      user = SS::User.authenticate(@cur_group, @item.in_id, @item.password)
      return if !user

      if params[:ref].blank? || [sns_login_path, sns_mypage_path].index(params[:ref])
        return set_user user, session: true, redirect: true, password: @item.password
      end

      set_user user, session: true, password: @item.password
      render action: :redirect
    end

    def logout
      put_history_log
      unset_user redirect: true
    end
end
