class Opendata::Agents::Nodes::MemberController < ApplicationController
  include Cms::NodeFilter::View
  #include Opendata::MypageFilter

  before_action :set_member

  protected
    def set_member
      @member = Opendata::Member.site(@cur_site).where(id: params[:member]).first
      raise "404" unless @member
    end

  public
    def index
      @datasets = Opendata::Dataset.site(@cur_site).public.
        where(member_id: @member.id)
    end
end
