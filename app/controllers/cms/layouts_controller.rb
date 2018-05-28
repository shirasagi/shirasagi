class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::TrashFilter

  model Cms::Layout

  navi_view "cms/main/navi"

  before_action :set_tree_navi, only: [:index, :trash]

  private

  def set_crumbs
    @crumbs << [t("cms.layout"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  public

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site, node: @cur_node)

    @node_target_options = @model.new.node_target_options

    @items = @model.site(@cur_site).
      node(@cur_node, params.dig(:s, :target)).
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
      allow(:read, @cur_user).
      only_deleted.
      search(params[:s]).
      order_by(filename: 1).
      page(params[:page]).per(50)
  end
end
