class Cms::LayoutsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter
  include Cms::SyntaxChecker

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
    @item = @model.new get_params
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    # アクセシビリティチェックを実行
    contents = [{ id: "layout", content: @item.html, resolve: "html" }]
    result = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    if result.errors.present?
      @item.errors.add :base, :syntax_check_error
      result.errors.each do |error|
        @item.errors.add :base, error[:msg]
      end
      render_create false
      return
    end

    render_create @item.save
  end

  def update
    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    raise "403" unless @item.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)

    # アクセシビリティチェックを実行
    contents = [{ id: "layout", content: @item.html, resolve: "html" }]
    result = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    if result.errors.present?
      @item.errors.add :base, :syntax_check_error
      result.errors.each do |error|
        @item.errors.add :base, error[:msg]
      end
      render_update false
      return
    end

    render_update @item.update
  end
end
