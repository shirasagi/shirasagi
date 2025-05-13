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

  def auto_correct
    Rails.logger.debug "[DEBUG] auto_correctメソッドが呼び出されました。"
    @syntax_checker.errors.each do |error|
      Rails.logger.debug "[DEBUG] error: #{error.inspect}"
      next unless error[:collector].present?
      Rails.logger.debug "[DEBUG] collector: #{error[:collector]}"
      Rails.logger.debug "[DEBUG] collector_params: #{error[:collector_params].inspect}"
      Rails.logger.debug "[DEBUG] code: #{error[:code].inspect}"
      before_html = @item.html
      Rails.logger.debug "[DEBUG] 修正前HTML: #{before_html.inspect}"
      params = (error[:collector_params] || {}).merge(code: error[:code])
      Rails.logger.debug "[DEBUG] correct呼び出し: collector=#{error[:collector]}, params=#{params.inspect}"
      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: error[:code],
        collector: error[:collector],
        params: error[:collector_params]
      )
      Rails.logger.debug "[DEBUG] Cms::SyntaxChecker.correctの戻り値: #{corrected.inspect}"
      html = corrected.respond_to?(:content) ? corrected.content : corrected
      Rails.logger.debug "[DEBUG] 修正後HTML: #{html.inspect}"
      if html.present? && html != before_html
        Rails.logger.debug "[DEBUG] HTMLが修正されました。@item.htmlを更新します。"
        @item.html = html
      else
        Rails.logger.debug "[DEBUG] HTMLは修正されませんでした。"
      end
    end
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
    if params[:auto_correct].present?
      auto_correct
      result = syntax_check
      render_create result
    end
    render_create @item.valid? && syntax_check && @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    if params[:auto_correct].present?
      Rails.logger.debug "[DEBUG] auto_correctフラグが存在します。"
      auto_correct
      result = syntax_check
      render_update result
    else
      render_update @item.valid? && syntax_check && @item.save
    end
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
