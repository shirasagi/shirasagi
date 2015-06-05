class Member::Agents::Nodes::LoginController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter

  skip_filter :logged_in?, only: [:login, :logout, :callback, :failure]

  private
    def get_params
      params.require(:item).permit(:email, :password)
    end

    def set_member_and_redirect(member)
      ref = URI::decode(params[:ref] || flash[:ref] || "")
      flash.discard(:ref)
      if ref.blank? || [member_login_path].index(ref)
        return set_member member, session: true, redirect: true
      end

      set_member member, session: true
      redirect_to ref
    end

  public
    def login
      @item = Cms::Member.new
      unless request.post?
        @error = flash[:alert]
        flash[:ref] = params[:ref]
        return
      end

      @item.attributes = get_params
      member = Cms::Member.site(@cur_site).where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first
      unless member
        # @item = Cms::Member.new email: @item.email
        @error = t "sns.errors.invalid_login"
        return
      end

      set_member_and_redirect member
    end

    def logout
      unset_member redirect: true
      flash.discard(:ref)
    end

    def callback
      auth = request.env["omniauth.auth"]
      member = Cms::Member.where(oauth_type: auth.provider, oauth_id: auth.uid).first
      if member.blank?
        #外部認証していない場合、ログイン情報を保存してから、ログインさせる
        Cms::Member.create_auth_member(auth, @cur_site)
        member = Cms::Member.where(oauth_type: auth.provider, oauth_id: auth.uid).first
      end

      set_member_and_redirect member
    end

    def failure
      session[:auth_site] = nil
      session[:member] = nil
      flash.discard(:ref)

      redirect_to "#{@cur_node.url}/login.html", alert: params[:message]
    end
end
