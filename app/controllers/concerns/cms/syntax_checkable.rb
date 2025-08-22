module Cms::SyntaxCheckable
  extend ActiveSupport::Concern

  private

  def set_check_item
    return @item if instance_variable_defined?(:@item)

    if params[:id].numeric?
      if respond_to?(:set_items)
        set_items
      else
        @items = @model.all
        if @model.ancestors.include?(Cms::GroupPermission)
          @items = @items.allow(:read, @cur_user, site: @cur_site)
        end
      end
      @item = @items.find(params[:id])
      if respond_to?(:change_item_class, true)
        change_item_class
      end
      # change_item_class を呼び出すと @model が適切にセットされる。
      # @model が適切な場合にのみ get_params は適切なパラメータを返す。
      # 例えば @model が Cms::Part の場合、Cms::Part::Free 用の html を get_params は含まない。
      @item.attributes = get_params
    else
      @item = @model.new get_params
      if respond_to?(:change_item_class, true)
        change_item_class
        @item = @model.new get_params
      end
    end

    @item
  end

  public

  def check_content
    set_check_item

    checks = params.expect(checks: [])
    checks = checks.map(&:strip).select(&:present?)
    if checks.blank?
      head :not_found
      return
    end
    checks = Set.new(checks)

    public_html = @item.try(:render_html) || @item.html
    syntax_checker_context = nil
    @components = []
    checks.each do |check|
      case check
      when "syntax", "form_alert"
        syntax_checker_context = Cms::SyntaxChecker.check_page(
          cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
        component = Cms::SyntaxCheckerComponent.new(
          cur_site: @cur_site, cur_user: @cur_user, checker_context: syntax_checker_context)
        @components << component
      when "mobile_size"
        mobile_size_checker = Cms::MobileSizeChecker.check(
          cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
        component = Cms::MobileSizeCheckerComponent.new(
          cur_site: @cur_site, cur_user: @cur_user, checker: mobile_size_checker)
        @components << component
      when "link"
        link_checker = Cms::ContentLinkChecker.check(
          cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
        component = Cms::ContentLinkCheckerComponent.new(
          cur_site: @cur_site, cur_user: @cur_user, checker: link_checker)
        @components << component
      else
        Rails.logger.info { "unknown check: #{check}" }
      end
    end

    if @item.persisted? && @item.is_a?(Cms::SyntaxCheckResult) && syntax_checker_context
      @item.set_syntax_check_result(syntax_checker_context)
    end

    if checks.include?("form_alert")
      errors_json = syntax_checker_context.errors.map { _1.to_compat_hash }
      response_json = { status: "ok", errors: errors_json }
      render json: response_json, status: :ok, content_type: json_content_type
      return
    end

    render template: "check_content", layout: false
  end

  def correct_content
    set_check_item

    corrector_param = Cms::SyntaxChecker::CorrectorParam.parse_params(params.expect(corrector: [:param])[:param])

    Cms::SyntaxChecker.correct_page(cur_site: @cur_site, cur_user: @cur_user, page: @item, params: corrector_param)

    # 修正結果を HTML で取得する
    if @item.try(:form_id).present?
      # 描画する addon を制限することで性能向上
      @addons = @item.addons.select { _1.id == "cms-agents-addons-form-page" }
      edit_html = render_to_string(template: "new", layout: false)
      fragment = Nokogiri::HTML5.fragment(edit_html)
      target_element = fragment.css("##{corrector_param.id}").first
      corrected_html = target_element.to_html
    else
      corrected_html = @item.html
    end

    public_html = @item.try(:render_html) || @item.html
    syntax_checker_context = Cms::SyntaxChecker.check_page(
      cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
    @components = [
      Cms::SyntaxCheckerComponent.new(
        cur_site: @cur_site, cur_user: @cur_user, checker_context: syntax_checker_context)
    ]
    check_result_html = render_to_string(template: "check_content", layout: false)

    if @item.persisted? && @item.is_a?(Cms::SyntaxCheckResult)
      @item.set_syntax_check_result(syntax_checker_context)
    end

    json = {
      id: corrector_param.id, column_value_id: corrector_param.column_value_id,
      corrected_html: corrected_html, check_result_html: check_result_html,
    }
    render json: json, status: :ok, content_type: json_content_type
  end
end
