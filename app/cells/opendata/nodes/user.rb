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
        @item = SS::User.new
        render
      end

      def login
        @item = SS::User.new get_params
        user = SS::User.where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first

        if user
          set_user user
          controller.redirect_to "#{@cur_node.url}#{user._id}/dataset/"
        else
          unset_user
          controller.redirect_to "#{@cur_node.url}"
        end
      end

      def logout
        session[:user] = nil
        controller.redirect_to "#{@cur_node.url}"
      end

    private
      def get_params
        params.require(:item).permit(:email, :password, :ref)
      end

      def set_user(user)
        session[:user] = SS::Crypt.encrypt("#{user._id},#{remote_addr},#{request.user_agent}")
        @cur_user = user
      end

      def unset_user
        session[:user] = nil
        @cur_user = nil
      end

      def remote_addr
        request.env["HTTP_X_REAL_IP"] || request.remote_addr
      end
  end
end
