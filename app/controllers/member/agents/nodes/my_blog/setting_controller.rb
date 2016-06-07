class Member::Agents::Nodes::MyBlog::SettingController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Cms::PublicFilter::Crud

  model Member::Node::BlogPage
  helper Member::MypageHelper

  before_action :set_item
  before_action :redirect_to_edit, only: [:new, :create]

  prepend_view_path "app/views/member/agents/nodes/my_blog/setting"

  private
    def set_item
      @blog_node = Member::Node::Blog.site(@cur_site).first
      @locations = Member::Node::BlogPageLocation.site(@cur_site).order_by(order: 1)
      @item = @model.site(@cur_site).node(@blog_node).member(@cur_member).first
      @cur_node.name += "設定"
    end

    def redirect_to_edit
      redirect_to "#{@cur_node.setting_url}edit" if @item
    end

    def fix_params
      { cur_site: @cur_site, cur_node: @blog_node, cur_member: @cur_member }
    end
end
