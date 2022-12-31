class Member::Agents::Nodes::BookmarkController < ApplicationController
  include Cms::NodeFilter::View
  include Member::LoginFilter
  include Cms::PublicFilter::FindContent

  helper Member::BookmarkHelper

  protect_from_forgery except: [:register, :cancel]

  before_action :logged_in?, if: -> { member_login_path }, only: :index
  before_action :set_path, only: [:register, :cancel]
  before_action :set_member, only: [:register, :cancel]

  private

  def set_path
    @path = params[:path]
    raise "404" if @path.blank?
  end

  def set_member
    raise "404" unless member_login_path
    @cur_member = get_member_by_session rescue nil
    redirect_to "#{member_login_path}?ref=#{CGI.escape(@path)}" if @cur_member.nil?
  end

  public

  def index
    @cur_member.squish_bookmarks
    @items = @cur_member.bookmarks.and_public.order_by(@cur_node.sort_hash).
      page(params[:page]).per(@cur_node.limit)
  end

  def register
    item = find_content(@cur_site, @path)
    @cur_member.register_bookmark(item) if item
    redirect_to(params[:ref].presence || @path)
  end

  def cancel
    item = find_content(@cur_site, @path)
    @cur_member.cancel_bookmark(item) if item
    redirect_to(params[:ref].presence || @path)
  end
end
