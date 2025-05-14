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
    error_index = params[:auto_correct].to_i
    Rails.logger.debug("[auto_correct] error_index: #{error_index}")
    @item.errors.clear
    contents = [{ "id" => "html", "content" => [@item.html], "resolve" => "html", "type" => "array" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    @syntax_checker.errors.each_with_index do |error, idx|
      next unless idx == error_index
      Rails.logger.debug("[auto_correct] 開始: @item.html=#{@item.html.inspect}")
      next unless error[:collector].present?
      before_html = @item.html
      Rails.logger.debug("[auto_correct] 修正前HTML: #{before_html.inspect}")

      content_value =
        if error[:collector] == 'Cms::SyntaxChecker::OrderOfHChecker'
          @item.html
        else
          error[:code]
        end

      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: {
          "content" => [content_value],
          "resolve" => "html",
          "type" => "array"
        },
        collector: error[:collector],
        params: (error[:collector_params] || {}).transform_keys(&:to_s)
      )

      Rails.logger.debug("[auto_correct] corrected.result: #{corrected.respond_to?(:result) ? corrected.result.inspect : corrected.inspect}")
      next unless corrected.respond_to?(:result)
      corrected_html = if corrected.result.is_a?(Array)
                         corrected.result.first.to_s
                       else
                         corrected.result.to_s
                       end

      Rails.logger.debug("[auto_correct] 修正後HTML(置換前): #{corrected_html.inspect}")
      corrected_html = corrected_html.gsub(/[	\r\n　 ]+/, "")
      Rails.logger.debug("[auto_correct] 修正後HTML(空白除去後): #{corrected_html.inspect}")
      next unless corrected_html.present? && corrected_html != error[:code]

      if error[:collector] == 'Cms::SyntaxChecker::OrderOfHChecker'
        @item.html = corrected_html
      else
        @item.html = replace_html_fragment(before_html, error[:code], corrected_html)
      end
      Rails.logger.debug("[auto_correct] 置換後@item.html: #{@item.html.inspect}")
    end
    Rails.logger.debug("[auto_correct] 終了: @item.html=#{@item.html.inspect}")
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
    if params.key?(:auto_correct)
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
    if params.key?(:auto_correct)
      auto_correct
      result = syntax_check
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

def replace_html_fragment(before_html, error_code, corrected_html)
  Rails.logger.debug("[replace_html_fragment] 呼び出し: before_html=#{before_html.inspect}, error_code=#{error_code.inspect}, corrected_html=#{corrected_html.inspect}")
  require 'nokogiri'
  before_doc = Nokogiri::HTML::DocumentFragment.parse(before_html)
  code_fragment = Nokogiri::HTML::DocumentFragment.parse(error_code.to_s)
  corrected_fragment = Nokogiri::HTML::DocumentFragment.parse(corrected_html)

  target_node = code_fragment.children.first
  tag_name = target_node ? target_node.name : nil
  attrs = target_node ? target_node.attribute_nodes.map { |attr| [attr.name, attr.value] }.to_h : {}

  replaced = false
  before_doc.css(tag_name).each do |node|
    match = attrs.all? { |k, v| node[k] == v }
    inner_html_match = node.inner_html.gsub(/\s+/, "") == target_node.inner_html.gsub(/\s+/, "")
    Rails.logger.debug("[replace_html_fragment] 比較: node=#{node.to_html.inspect}, match=#{match}, inner_html_match=#{inner_html_match}")
    next unless match && inner_html_match
    node.replace(corrected_fragment)
    replaced = true
    Rails.logger.debug("[replace_html_fragment] 置換成功: node=#{node.to_html.inspect}")
    break
  end

  result_html = replaced ? before_doc.to_html : before_html
  Rails.logger.debug("[replace_html_fragment] 結果: replaced=#{replaced}, result_html=#{result_html.inspect}")
  result_html
end
