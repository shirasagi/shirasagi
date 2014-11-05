class Opendata::Agents::Nodes::MypageController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::MypageFilter

  skip_filter :logged_in?, only: [:login, :logout, :provide]

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

    def provide
      session[:auth_site] = @cur_site
      %w[twitter facebook yahoojp google_oauth2 github].each do |name|
        redirect_to "/auth/#{name}" if request.path_info.include?(name)
      end
    end
end
