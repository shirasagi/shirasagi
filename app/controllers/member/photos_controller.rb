class Member::PhotosController < ApplicationController
  include Cms::BaseFilter
  include Member::Photo::PageFilter

  model Member::Photo

  navi_view "cms/node/main/navi"

  before_action :set_category

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  def set_category
    @categories = Member::Node::PhotoCategory.site(@cur_site).and_public
    @locations  = Member::Node::PhotoLocation.site(@cur_site).and_public
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @items = @model.site(@cur_site).node(@cur_node).
      allow(:read, @cur_user, site: @cur_site).
      search(params[:s]).
      order_by(updated: -1).
      page(params[:page]).per(50)
  end
end
