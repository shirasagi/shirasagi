module Cms::LayoutsHelper
  # error[:detail]用
  def syntax_check_detail_box(syntax_checker)
    return unless syntax_checker&.errors.present?
    syntax_checker.errors.each do |error|
      Rails.logger.debug "[DEBUG] error object in syntax_check_detail_box: #{error.inspect}"
    end
    content_tag(:div, id: "errorSyntaxChecker", class: "errorExplanation") do
      concat content_tag(:h2, t("cms.syntax_check"))
      concat(
        content_tag(:div, class: "errorExplanationBody") do
          concat content_tag(:p, t("errors.template.body"))
          concat(
            content_tag(:ul) do
              syntax_checker.errors.each_with_index do |error, idx|
                concat render_error_detail(error, idx)
              end
            end
          )
        end
      )
    end
  end

  private

  def render_error_detail(error, idx = nil)
    safe_join([
      render_column_name(error),
      render_error_code(error),
      render_error_message(error, idx)
    ].compact)
  end

  def render_column_name(error)
    return unless error[:id].present?
    content_tag(:li, error[:id], class: "column-name")
  end

  def render_error_code(error)
    return unless error[:code].present?
    content_tag(:li, class: "code") do
      content_tag(:code, error[:code].to_s)
    end
  end

  def render_error_message(error, idx = nil)
    return unless error[:msg].present?
    content_tag(:ul) do
      content_tag(:li) do
        content_tag(:span, class: "message detail") do
          safe_join([
            error[:msg].to_s,
            error[:detail].present? ? render_tooltip(error[:detail]) : nil,
            render_auto_correct_button(error, idx)
          ].compact)
        end
      end
    end
  end

  def render_tooltip(detail)
    return unless detail.present?
    content_tag(:div, class: "tooltip") do
      "!".html_safe +
        content_tag(:ul, class: "tooltip-content") do
          Array(detail).map { |d| content_tag(:li, d.to_s) }.join.html_safe
        end
    end
  end

  def render_auto_correct_button(error, idx = nil)
    return unless error[:collector].present?
    content_tag(:button, I18n.t("cms.auto_correct.link"),
      type: "submit",
      class: "btn btn-auto-correct",
      name: "auto_correct",
      value: idx
    )
  end
end
