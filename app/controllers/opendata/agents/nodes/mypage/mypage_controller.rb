class Opendata::Agents::Nodes::Mypage::MypageController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Opendata::MemberFilter
  helper Opendata::UrlHelper

  before_action :get_member_notice, only: [:show_notice, :confirm_notice]

  private
    def get_member_notice
      if @cur_member
        @notice ||= Opendata::MemberNotice.where({site_id: @cur_site.id, member_id: @cur_member.id}).first
      end
    end

  public
    def index
      if view_context.dataset_enabled?
        redirect_to view_context.my_dataset_path
      else
        redirect_to view_context.my_app_path
      end
    end

    def show_notice
      @cur_node.layout = nil
    end

    def confirm_notice
      @cur_node.layout = nil

      @notice.commented_count = 0
      @notice.confirmed = Time.zone.now
      @notice.save!

      redirect_to "#{@cur_node.url}notice/show.html"
    end
end
