module Opendata::Nodes::Mypage
  class ViewCell < Cell::Rails
    include Cms::NodeFilter::ViewCell
    include Opendata::MypageFilter

    skip_filter :logged_in?, only: [:login, :logout, :provider]

    private
      def get_params
        params.require(:item).permit(:email, :password)
      end

    public
      def index
        controller.redirect_to "/mypage/dataset/" if @cur_member
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
          controller.redirect_to "/auth/twitter"
        elsif request.path_info.include?("facebook")
          controller.redirect_to "/auth/facebook"
        elsif request.path_info.include?("yahoojp")
          controller.redirect_to "/auth/yahoojp"
        elsif request.path_info.include?("google_oauth2")
          controller.redirect_to "/auth/google_oauth2"
        end
      end
  end
end
