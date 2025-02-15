class Member::Agents::Pages::BlogPageController < ApplicationController
  include Cms::PageFilter::View

  helper Member::BlogPageHelper

  before_action :deny
  after_action :render_blog_layout

  def deny
    raise SS::NotFoundError unless @cur_page.parent.public?
  end

  def render_blog_layout
    return if response.media_type != "text/html"

    node = @cur_page.parent
    @cur_page.layout = node.page_layout
    layout = @cur_page.layout
    layout.html = layout.html.gsub(/\#\{(.+?)\}/) do |m|
      name = $1
      view_context.render_blog_template(name, node: node) || m
    end
    @cur_page.layout = layout
  end
end
