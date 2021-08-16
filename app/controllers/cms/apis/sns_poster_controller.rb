class Cms::Apis::SnsPosterController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model ::Cms::Page

  public

  def line_reset
    set_item
    @item = @item.becomes_with_route
    @item.reset_line_posted! if @item.respond_to?(:reset_line_posted!)
    redirect_to @item.private_show_path, notice: t("ss.notice.reset_posted")
  end

  def twitter_reset
    set_item
    @item = @item.becomes_with_route
    @item.reset_twitter_posted! if @item.respond_to?(:reset_twitter_posted!)
    redirect_to @item.private_show_path, notice: t("ss.notice.reset_posted")
  end
end
