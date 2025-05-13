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
    @item.errors.clear # エラーメッセージをクリア
    contents = [{ "id" => "html", "content" => [@item.html], "resolve" => "html", "type" => "array" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    Rails.logger.debug "[DEBUG] auto_correctメソッドが呼び出されました。"
    Rails.logger.debug "[DEBUG] @syntax_checker.errors: #{@syntax_checker.errors.inspect}"

    @syntax_checker.errors.each do |error|
      Rails.logger.debug "[DEBUG] エラー処理開始: #{error.inspect}"
      Rails.logger.debug "[DEBUG] collector存在確認: #{error[:collector].present?}"

      next unless error[:collector].present?
      Rails.logger.debug "[DEBUG] collector: #{error[:collector]}"
      Rails.logger.debug "[DEBUG] collector_params: #{error[:collector_params].inspect}"
      Rails.logger.debug "[DEBUG] code: #{error[:code].inspect}"
      before_html = @item.html
      Rails.logger.debug "[DEBUG] 修正前HTML: #{before_html.inspect}"

      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: {
          "content" => [error[:code]],
          "resolve" => "html",
          "type" => "array"
        },
        collector: error[:collector],
        params: error[:collector_params].transform_keys(&:to_s)
      )
      Rails.logger.debug "[DEBUG] Cms::SyntaxChecker.correctの戻り値: #{corrected.inspect}"

      if corrected.respond_to?(:result)
        corrected_html = corrected.result.to_s

        if corrected_html.present? && corrected_html != error[:code]
          # Nokogiriでタグ名＋主要属性一致で置換
          require 'nokogiri'
          before_doc = Nokogiri::HTML::DocumentFragment.parse(before_html)
          code_fragment = Nokogiri::HTML::DocumentFragment.parse(error[:code].to_s)
          corrected_fragment = Nokogiri::HTML::DocumentFragment.parse(corrected_html)

          target_node = code_fragment.children.first
          tag_name = target_node&.name
          attrs = target_node&.attribute_nodes&.map { |attr| [attr.name, attr.value] }&.to_h || {}

          replaced = false
          before_doc.css(tag_name).each do |node|
            # 主要属性（id, class, name, href, src, alt, etc.）が一致するか判定
            match = attrs.all? do |k, v|
              node[k] == v
            end
            # inner_htmlも近いかどうか（空白除去で比較）
            inner_html_match = node.inner_html.gsub(/\s+/, "") == target_node.inner_html.gsub(/\s+/, "")

            next unless match && inner_html_match
            node.replace(corrected_fragment)
            replaced = true
            break
          end

          new_html = replaced ? before_doc.to_html : before_html
          Rails.logger.debug "[DEBUG] 置換後のHTML: #{new_html.inspect}"
          @item.html = new_html
        else
          Rails.logger.debug "[DEBUG] HTMLは修正されませんでした。"
        end
      else
        Rails.logger.debug "[DEBUG] 修正結果が不正な形式です: #{corrected.inspect}"
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
      return
    end
    render_create @item.valid? && syntax_check && @item.save
  end

  def update
    raise "403" unless @model.allowed?(:edit, @cur_user, site: @cur_site, node: @cur_node)
    @item.attributes = get_params
    if params[:auto_correct].present?
      Rails.logger.debug "[DEBUG] auto_correctフラグが存在します。"
      Rails.logger.debug "[DEBUG] auto_correct実行前の@item.html: #{@item.html.inspect}"
      auto_correct
      Rails.logger.debug "[DEBUG] auto_correct実行後の@item.html: #{@item.html.inspect}"
      result = syntax_check
      Rails.logger.debug "[DEBUG] syntax_checkの結果: #{result.inspect}"
      render_update result
      return
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
