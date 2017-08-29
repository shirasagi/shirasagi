class Cms::Node::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter

  model Cms::Page

  prepend_view_path "app/views/cms/pages"
  navi_view "cms/node/main/navi"

  private

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: @cur_node }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @node_target_options = @model.new.node_target_options

    @items = @model.site(@cur_site).
      node(@cur_node, params.dig(:s, :target)).
      where(route: "cms/page").
      allow(:read, @cur_user).
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
