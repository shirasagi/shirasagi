class Opendata::Agents::Nodes::MemberController < ApplicationController
  include Cms::NodeFilter::View
  helper Opendata::UrlHelper

  before_action :set_member, except: :index

  protected

  def set_member
    @member = Opendata::Member.site(@cur_site).where(id: params[:member]).first
    raise "404" unless @member

    @member_url = "#{@cur_node.url}#{@member.id}/"
  end

  public

  def index
    raise "404"
  end

  def show
    @datasets = Opendata::Dataset.site(@cur_site).and_public.
      where(member_id: @member.id).
      order_by(released: -1).
      limit(10)

    apps
    ideas
  end

  def datasets
    @datasets = Opendata::Dataset.site(@cur_site).and_public.
      where(member_id: @member.id).
      order_by(released: -1).
      page(params[:page]).
      per(50)
  end

  def apps
    @apps = Opendata::App.site(@cur_site).and_public.
      where(member_id: @member.id).
      order_by(released: -1).
      page(params[:page]).
      per(50)
  end

  def ideas
    @ideas = Opendata::Idea.site(@cur_site).and_public.
      where(member_id: @member.id).
      order_by(released: -1).
      page(params[:page]).
      per(50)
  end
end
