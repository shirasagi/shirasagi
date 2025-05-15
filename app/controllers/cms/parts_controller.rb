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
    contents = [{ "id" => "html", "content" => @item.html, "resolve" => "html", "type" => "scalar" }]
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

    # 構文チェックを実行
    contents = [{ "id" => "html", "content" => [@item.html.to_s], "resolve" => "html", "type" => "array" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    # 指定されたエラーインデックスのエラーを修正
    @syntax_checker.errors.each_with_index do |error, idx|
      next unless idx == error_index
      Rails.logger.debug("[auto_correct] 開始: @item.html=#{@item.html.inspect}")

      # エラーにcollectorが設定されている場合のみ修正を試みる
      next unless error[:collector].present?

      before_html = @item.html
      Rails.logger.debug("[auto_correct] 修正前HTML: #{before_html.inspect}")

      content_value =
        if error[:collector] == 'Cms::SyntaxChecker::OrderOfHChecker' || error[:collector] == 'Cms::SyntaxChecker::TableChecker'
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

      # 修正結果の処理
      next unless corrected.respond_to?(:result)
      corrected_html = if corrected.result.is_a?(Array)
                         corrected.result.first.to_s
                       else
                         corrected.result.to_s
                       end

      Rails.logger.debug("[auto_correct] 修正後HTML(置換前): #{corrected_html.inspect}")

      # 修正結果が有効な場合のみ適用
      next unless corrected_html.present? && corrected_html != error[:code]

      # collectorごとに置換方法を分岐
      case error[:collector]
      when 'Cms::SyntaxChecker::OrderOfHChecker', 'Cms::SyntaxChecker::TableChecker'
        # 全体置換
        @item.html = corrected_html
      else
        # 部分置換
        @item.html = replace_html_fragment(before_html, error[:code], corrected_html)
      end
    end
  end

  def replace_html_fragment(before_html, error_code, corrected_html)
    Rails.logger.debug("[replace_html_fragment] 呼び出し: before_html=#{before_html.inspect}, error_code=#{error_code.inspect}, corrected_html=#{corrected_html.inspect}")

    escaped_code = Regexp.escape(error_code)
    pattern = escaped_code.gsub(/\\r\\n|\\n|\\r/, '\s*') # 改行を任意の空白文字に変換
    pattern = pattern.gsub(/>\s*</, '>\s*<') # タグ間の空白を許容

    Rails.logger.debug("[replace_html_fragment] 生成されたパターン: #{pattern}")

    replaced_text = before_html.gsub(/#{pattern}/, corrected_html)

    Rails.logger.debug("[replace_html_fragment] 置換後: replaced_text=#{replaced_text.inspect}")
    return replaced_text
  end

  def replace_html_fragment_with_nokogiri(before_html, error_code, corrected_html)
    require 'nokogiri'
    Rails.logger.debug("[replace_html_fragment_with_nokogiri] 開始: error_code=#{error_code.inspect}, corrected_html=#{corrected_html.inspect}")

    before_doc = Nokogiri::HTML::DocumentFragment.parse(before_html)
    code_fragment = Nokogiri::HTML::DocumentFragment.parse(error_code.to_s)
    corrected_fragment = Nokogiri::HTML::DocumentFragment.parse(corrected_html)

    # error_codeがtableタグの場合、そのtableを探して置換
    if code_fragment.at('table')
      before_doc.css('table').each do |table_node|
        # tableのHTMLを比較して一致するものを探す
        next unless table_node.to_html.gsub(/\s+/, "") == code_fragment.at('table').to_html.gsub(/\s+/, "")
        Rails.logger.debug("  置換実行: #{table_node.to_html} → #{corrected_fragment.to_html}")
        table_node.replace(corrected_fragment)
        break
      end
    else
      # fallback: 既存のロジック
      target_node = code_fragment.children.first
      tag_name = target_node ? target_node.name : nil
      attrs = target_node ? target_node.attribute_nodes.map { |attr| [attr.name, attr.value] }.to_h : {}

      replaced = false
      if tag_name
        before_doc.css(tag_name).each do |node|
          match = attrs.all? { |k, v| node[k] == v }
          text_match = node.text.gsub(/\s+/, "") == target_node.text.gsub(/\s+/, "")
          next unless match && text_match
          node.replace(corrected_fragment)
          replaced = true
          break
        end
      end
    end

    result_html = before_doc.to_html
    Rails.logger.debug("[replace_html_fragment_with_nokogiri] 結果: result_html=#{result_html}")
    result_html
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
