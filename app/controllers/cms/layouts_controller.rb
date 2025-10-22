class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SyntaxCheckable
  helper Cms::SyntaxCheckableHelper

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

    result = @item.valid?
    @syntax_context = Cms::SyntaxChecker.check_page(cur_site: @cur_site, cur_user: @cur_user, page: @item)
    unless params.key?(:ignore_syntax_check)
      if @syntax_context.errors.present?
        @item.errors.add :html, :accessibility_error
        result = false
      end
    end

    unless result
      render_create result
      return
    end

    @item.syntax_check_result_checked = Time.zone.now.utc
    @item.syntax_check_result_violation_count = @syntax_context.errors.select { _1.id.present? }.count

    render_create @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params

    result = @item.valid?
    @syntax_context = Cms::SyntaxChecker.check_page(cur_site: @cur_site, cur_user: @cur_user, page: @item)
    unless params.key?(:ignore_syntax_check)
      if @syntax_context.errors.present?
        @item.errors.add :html, :accessibility_error
        result = false
      end
    end

    unless result
      render_update result
      @item.set_syntax_check_result(@syntax_context)
      return
    end

    @item.syntax_check_result_checked = Time.zone.now.utc
    @item.syntax_check_result_violation_count = @syntax_context.errors.select { _1.id.present? }.count

    render_update @item.save
  end
end
