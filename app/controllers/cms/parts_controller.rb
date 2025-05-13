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
    @item.errors.clear
    contents = [{ "id" => "html", "content" => [@item.html], "resolve" => "html", "type" => "array" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    @syntax_checker.errors.each do |error|
      next unless error[:collector].present?
      before_html = @item.html

      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: {
          "content" => [error[:code]],
          "resolve" => "html",
          "type" => "array"
        },
        collector: error[:collector],
        params: (error[:collector_params] || {}).transform_keys(&:to_s)
      )

      next unless corrected.respond_to?(:result)
      corrected_html = corrected.result.to_s
      next unless corrected_html.present? && corrected_html != error[:code]

      @item.html = replace_html_fragment(before_html, error[:code], corrected_html)
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
    next unless match && inner_html_match
    node.replace(corrected_fragment)
    replaced = true
    break
  end

  replaced ? before_doc.to_html : before_html
end
