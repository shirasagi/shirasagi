class Cms::Node::PagesController < ApplicationController
  include Cms::BaseFilter
  include Cms::PageFilter
  include Cms::TrashFilter

  model Cms::Page

  prepend_view_path "app/views/cms/pages"
  navi_view "cms/node/main/navi"

  before_action :set_tree_navi, only: [:index, :trash]

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

  def trash
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @node_target_options = @model.new.node_target_options

    @items = @model.unscope_and.site(@cur_site).
      node(@cur_node, params.dig(:s, :target)).
      where(route: "cms/page").
      allow(:read, @cur_user).
      only_deleted.
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
