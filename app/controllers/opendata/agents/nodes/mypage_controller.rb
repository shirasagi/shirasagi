class Opendata::Agents::Nodes::MypageController < ApplicationController
  include Cms::NodeFilter::View
  include Opendata::MypageFilter

  skip_filter :logged_in?, only: [:login, :logout, :provide]

  before_action :get_member_notice, only: [:show_notice, :confirm_notice]

  PROVIDERS = %w(twitter facebook yahoojp google_oauth2 github).freeze

  private
    def get_params
      params.require(:item).permit(:email, :password)
    end

    def get_member_notice
      if @cur_member
        @notice = Opendata::MemberNotice.where({site_id: @cur_site.id, member_id: @cur_member.id}).first
      end
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

    def show_notice
      @cur_node.layout = nil
    end

    def confirm_notice
      @cur_node.layout = nil

      @notice.commented_count = 0
      @notice.confirmed = Time.zone.now
      @notice.save!

      render :show_notice
    end

    def provide
      session[:auth_site] = @cur_site
      provider = PROVIDERS.find { |name| request.path_info.include?(name) }
      redirect_to "/auth/#{provider}" if provider.present?
    end
end
