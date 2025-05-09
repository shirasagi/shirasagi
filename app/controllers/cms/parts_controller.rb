class Cms::PartsController < ApplicationController
  include Cms::BaseFilter
  include Cms::PartFilter
  include Cms::LayoutsHelper

  helper Cms::LayoutsHelper

  model Cms::Part

  navi_view "cms/main/navi"

  before_action :set_tree_navi, only: [:index]
  before_action :syntax_check, only: [:create, :update]

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

  def syntax_check
    contents = [{ "id" => "html", "content" => [@item.html], "resolve" => "html", "type" => "array" }]

    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    if @syntax_checker.errors.present?
      @syntax_checker.errors.each do |error|
        @item.errors.add :base, error[:msg]
      end
      return false
    end
    true
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
    raise "403" unless @model.allowed?(:create, @cur_user, site: @cur_site, node: @cur_node)
    @item = @model.new get_params
    render_create @item.valid? && syntax_check && @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    render_update @item.valid? && syntax_check && @item.save
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
