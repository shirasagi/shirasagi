class Member::Agents::Nodes::MyBlogController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Cms::PublicFilter::Crud

  model Member::BlogPage
  helper Member::MypageHelper

  before_action :set_blog_node

  prepend_view_path "app/views/member/agents/nodes/my_blog"

  helper Cms::ListHelper

  private
    def fix_params
      { cur_site: @cur_site, cur_member: @cur_member, cur_node: @blog_page_node }
    end

    def set_blog_node
      @blog_node      = Member::Node::Blog.site(@cur_site).first
      @blog_page_node = Member::Node::BlogPage.site(@cur_site).node(@blog_node).member(@cur_member).first
      @locations      = Member::Node::BlogPageLocation.site(@cur_site).order_by(order: 1)
      #@cur_node.name = @item.name
      redirect_to "#{@cur_node.setting_url}new" unless @blog_page_node
    end

  public
    def index
      @items = @model.site(@cur_site).member(@cur_member).
        order_by(released: -1).
        page(params[:page]).per(50)
    end

    def new
      @item = @model.new pre_params.merge(fix_params)
      @item.blog_page_location_ids = @blog_page_node.blog_page_location_ids
    end

    def update
      @item.attributes = get_params
      @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
      render_update @item.update, { action: "show"}
    end
end
