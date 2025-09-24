class Cms::PartsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PartFilter
  include Cms::SyntaxCheckable
  helper Cms::SyntaxCheckableHelper

  model Cms::Part

  navi_view "cms/main/navi"

  before_action :set_tree_navi, only: [:index]

  private

  def set_crumbs
    @crumbs << [t("cms.part"), action: :index]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site, cur_node: false }
  end

  def pre_params
    { route: "cms/free" }
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
    change_item_class
    @item.attributes = get_params

    result = @item.valid?
    if @item.is_a?(Cms::SyntaxCheckResult)
      @syntax_context = Cms::SyntaxChecker.check_page(cur_site: @cur_site, cur_user: @cur_user, page: @item)
    end
    if !params.key?(:ignore_syntax_check) && @syntax_context && @syntax_context.errors.present?
      @item.errors.add :html, :accessibility_error
      result = false
    end

    unless result
      render_create result
      return
    end

    if @item.is_a?(Cms::SyntaxCheckResult)
      @item.syntax_check_result_checked = Time.zone.now.utc
      @item.syntax_check_result_violation_count = @syntax_context.errors.select { _1.id.present? }.count
    end

    render_create @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params

    result = @item.valid?
    if @item.is_a?(Cms::SyntaxCheckResult)
      @syntax_context = Cms::SyntaxChecker.check_page(cur_site: @cur_site, cur_user: @cur_user, page: @item)
    end
    if !params.key?(:ignore_syntax_check) && @syntax_context && @syntax_context.errors.present?
      @item.errors.add :html, :accessibility_error
      result = false
    end

    unless result
      render_update result
      if @item.is_a?(Cms::SyntaxCheckResult)
        @item.set_syntax_check_result(@syntax_context)
      end
      return
    end

    if @item.is_a?(Cms::SyntaxCheckResult)
      @item.syntax_check_result_checked = Time.zone.now.utc
      @item.syntax_check_result_violation_count = @syntax_context.errors.select { _1.id.present? }.count
    end

    render_update @item.save
  end

  def routes
    @items = {}

    Cms::Part.new.route_options.each do |name, path|
      mod = path.sub(/\/.*/, '')
      @items[mod] = { name: t("modules.#{mod}"), items: [] } if !@items[mod]
      @items[mod][:items] << [ name.sub(/.*\//, ""), path ]
    end

    render template: "cms/nodes/routes", layout: "ss/ajax"
  end
end
