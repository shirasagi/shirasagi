class Member::BlogPagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Member::BlogPage

  before_action :set_blog_page_nodes

  private
    def fix_params
      { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
    end

    def set_blog_page_nodes
      @cur_node  = @cur_node.becomes_with_route
      @locations = Member::Node::BlogPageLocation.site(@cur_site).order_by(order: 1)
    end

  public
    def new
      super
      @item.blog_page_location_ids = @cur_node.blog_page_location_ids
    end
end
