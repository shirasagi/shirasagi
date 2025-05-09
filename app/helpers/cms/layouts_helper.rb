module Cms::LayoutsHelper
  # error[:detail]用
  def syntax_check_detail_box(syntax_checker)
    return unless syntax_checker&.errors.present?
    content_tag(:div, id: "errorSyntaxChecker", class: "errorExplanation") do
      concat content_tag(:h2, t("cms.syntax_check"))
      concat(
        content_tag(:div, class: "errorExplanationBody") do
          concat content_tag(:p, t("errors.template.body"))
          concat(
            content_tag(:ul) do
              syntax_checker.errors.each do |error|
                next unless error[:detail].present?
                # カラム名（例：添付ファイル）
                concat content_tag(:li, error[:id], class: "column-name") if error[:id].present?
                # コード（例：ファイル名）
                if error[:code].present?
                  concat(content_tag(:li, class: "code") do
                    content_tag(:code, error[:code].to_s)
                  end)
                end
                # 詳細（例：ファイル名を入力してください。）
                concat(
                  content_tag(:ul) do
                    Array(error[:detail]).map do |d|
                      content_tag(:li) do
                        content_tag(:span, d.to_s, class: "message detail")
                      end
                    end.join.html_safe
                  end
                )
              end
            end
          )
        end
      )
    end
  end
end
