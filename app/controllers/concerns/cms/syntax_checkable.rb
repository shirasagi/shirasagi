module Cms::SyntaxCheckable
  extend ActiveSupport::Concern

  private

  def set_check_item
    return @item if instance_variable_defined?(:@item)

    @item = @model.new get_params
    if respond_to?(:change_item_class, true)
      change_item_class
      @item = @model.new get_params
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

    public_html = @item.try(:render_html) || @item.html
    form_alert = false
    @components = []
    while checks.count > 0
      check = checks.shift
      case check
      when "syntax", "form_alert"
        syntax_checker_context = Cms::SyntaxChecker.check_page(
          cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
        component = Cms::SyntaxCheckerComponent.new(
          cur_site: @cur_site, cur_user: @cur_user, checker_context: syntax_checker_context)
        @components << component

        if check == "form_alert"
          form_alert = true
        end
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

    if form_alert
      errors_json = syntax_checker_context.errors.map { _1.to_compat_hash }
      response_json = { status: "ok", errors: errors_json }
      render json: response_json, status: :ok, content_type: json_content_type
    else
      render template: "check_content", layout: false
    end
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
    result = Cms::SyntaxChecker.check_page(cur_site: @cur_site, cur_user: @cur_user, page: @item, html: public_html)
    @components = [
      Cms::SyntaxCheckerComponent.new(cur_site: @cur_site, cur_user: @cur_user, checker_context: result)
    ]
    check_result_html = render_to_string(template: "check_content", layout: false)

    json = {
      id: corrector_param.id, column_value_id: corrector_param.column_value_id,
      corrected_html: corrected_html, check_result_html: check_result_html,
    }
    render json: json, status: :ok, content_type: json_content_type
  end
end
