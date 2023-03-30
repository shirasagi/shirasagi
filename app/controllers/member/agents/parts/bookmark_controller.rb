class Member::Agents::Parts::BookmarkController < ApplicationController
  include Cms::PartFilter::View
  include Member::AuthFilter
  include Cms::PublicFilter::FindContent
  helper Cms::ListHelper

  before_action :set_bookmark_node
  #before_action :set_cur_content
  before_action :set_member

  def member_login_node
    @member_login_node ||= begin
      node = Member::Node::Login.site(@cur_site).and_public.first
      node.present? ? node : false
    end
  end

  def member_login_path
    return false unless member_login_node
    "#{member_login_node.url}login.html"
  end

  def set_bookmark_node
    if @cur_part.parent.try(:route) == "member/bookmark"
      @bookmark_node = @cur_part.parent.becomes_with_route
    else
      @bookmark_node = Member::Node::Bookmark.site(@cur_site).first
    end
    raise "404" unless @bookmark_node
  end

  #def set_cur_content
  #  @cur_content = find_content(@cur_site, @cur_path)
  #  raise "404" unless @cur_content
  #end

  def set_member
    raise "404" unless member_login_path
    @cur_member = get_member_by_session rescue nil
    @redirect_path = "#{member_login_path}?ref=#{CGI.escape(@cur_path)}"
  end

  def index
  end
end
