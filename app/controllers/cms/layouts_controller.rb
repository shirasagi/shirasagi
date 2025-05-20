class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SyntaxCheckable

  model Cms::Layout

  navi_view "cms/main/navi"

  before_action :set_tree_navi, only: [:index]

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

  def create
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item = @model.new get_params

    if params.key?(:ignore_syntax_check)
      render_create @item.valid? && @item.save
      return
    end

    result = syntax_check

    if params.key?(:auto_correct)
      auto_correct
      render_create result
      return
    end
    render_create @item.valid? && syntax_check && @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    if params.key?(:ignore_syntax_check)
      # 警告無視で保存
      render_update @item.valid? && @item.save
      return
    end

    result = syntax_check

    if params.key?(:auto_correct)
      auto_correct
      render_update result
      return
    else
      render_update @item.valid? && syntax_check && @item.save
    end
  end
end
