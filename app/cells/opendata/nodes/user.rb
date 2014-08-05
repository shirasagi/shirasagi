# coding: utf-8
module Opendata::Nodes::User
  class EditCell < Cell::Rails
    include Cms::NodeFilter::EditCell
    model Opendata::Node::User

  end

  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include SS::LayoutFilter

    #before_action :logged_in?, only: [:login, :logout]
    #skip_filter :logged_in?, only: [:login, :logout]

    public
      def index
        render
      end

      def login
        @item = SS::User.new
        @item.email    = params[:email]
        @item.password = params[:password]
        return if !request.post?

        @item.attributes = get_params
        user = SS::User.where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first
        return if !user

        if user
          reset_session
          session[:user] = SS::Crypt.encrypt("#{user._id},#{remote_addr},#{request.user_agent}")
        else
          flash.now[:referer] = params[:referer]
          @error = "Error"
          render "index"
        end

=begin
        if params[:ref].blank? || [node_opendata_path, node_opendata_path].index(params[:ref])
          return set_user user, session: true, redirect: true
        end

        set_user user, session: true
        render file: "views/sns/login/redirect"
=end
      end

      def logout
        reset_session
        redirect_to "/"
=begin
        unset_user redirect: true
=end
      end

    private
#login_controllerより
      def get_params
        params.require(:item).permit(:email, :password, :ref)
      end
#SS::BaseFilterより
      def logged_in?

        if session[:user]
          begin
            u = SS::Crypt.decrypt(session[:user]).to_s.split(",", 3)
          rescue ActiveRecord::RecordNotFound
            reset_session
          end
        end

        unless u
          #flash[:referer] = request.fullpath
          ref = request.env["REQUEST_URI"]
          ref = (ref == node_opendata_path) ? "" : "?ref=" + CGI.escape(ref.to_s)
          redirect_to "#{node_opendata_path}#{ref}"
        end
=begin
        return @cur_user if @cur_user

        if session[:user]
          u = SS::Crypt.decrypt(session[:user]).to_s.split(",", 3)
          return unset_user redirect: true if u[1] != remote_addr
          return unset_user redirect: true if u[2] != request.user_agent
          @cur_user = SS::User.find u[0].to_i rescue nil
        end

        return @cur_user if @cur_user
        unset_user

        ref = request.env["REQUEST_URI"]
        ref = (ref == sns_mypage_path) ? "" : "?ref=" + CGI.escape(ref.to_s)
        redirect_to "#{sns_login_path}#{ref}"
=end
      end

      def set_user(user, opt = {})
        if opt[:session]
          session[:user] = SS::Crypt.encrypt("#{user._id},#{remote_addr},#{request.user_agent}")
        end
        redirect_to sns_mypage_path if opt[:redirect]
        @cur_user = user
      end

      def unset_user(opt = {})
        session[:user] = nil
        redirect_to sns_login_path if opt[:redirect]
        @cur_user = nil
      end
  end
end
