class Opendata::Agents::Nodes::MemberController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  before_action :set_member

  protected
    def set_member
      @member = Opendata::Member.site(@cur_site).where(id: params[:member]).first
      raise "404" unless @member
    end

  public
    def index
      @datasets = Opendata::Dataset.site(@cur_site).public.
        where(member_id: @member.id).
        order_by(released: -1).
        limit(10)

      ideas
    end

    def datasets
      @datasets = Opendata::Dataset.site(@cur_site).public.
        where(member_id: @member.id).
        order_by(released: -1).
        page(params[:page]).
        per(20)
    end

    def ideas
      @ideas = Opendata::Idea.site(@cur_site).public.
        where(member_id: @member.id).
        order_by(released: -1).
        page(params[:page]).
        per(20)
    end
end
