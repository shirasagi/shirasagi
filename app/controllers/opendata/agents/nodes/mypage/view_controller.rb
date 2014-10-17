module Opendata::Agents::Nodes::Mypage
  class ViewController < ApplicationController
    include Cms::NodeFilter::View
    include Opendata::MypageFilter

    skip_filter :logged_in?, only: [:login, :logout, :provider]

    private
      def get_params
        params.require(:item).permit(:email, :password)
      end

    public
      def index
        redirect_to "/mypage/dataset/" if @cur_member
      end

      def login
        @item = Cms::Member.new
        return render unless request.post?

        @item.attributes = get_params
        member = Cms::Member.where(email: @item.email, password: SS::Crypt.crypt(@item.password)).first
        return render if !member

        set_member member, session: true, redirect: true
      end

      def logout
        unset_member redirect: true
      end

      def provider
        session[:site] = SS::Site.find_by host: params[:site]
        if request.path_info.include?("twitter")
          redirect_to "/auth/twitter"
        elsif request.path_info.include?("facebook")
          redirect_to "/auth/facebook"
        elsif request.path_info.include?("yahoojp")
          redirect_to "/auth/yahoojp"
        elsif request.path_info.include?("google_oauth2")
          redirect_to "/auth/google_oauth2"
        end
      end
  end
end
