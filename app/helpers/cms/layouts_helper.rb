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
                    content_tag(:li) do
                      # メッセージ＋ツールチップをspan内にまとめる
                      content_tag(:span, class: "message detail") do
                        inner_html = error[:msg].to_s
                        if error[:detail].present?
                          inner_html += content_tag(:div, class: "tooltip") do
                            "!".html_safe +
                            content_tag(:ul, class: "tooltip-content") do
                              Array(error[:detail]).map { |d| content_tag(:li, d.to_s) }.join.html_safe
                            end
                          end
                        end
                        # 自動修正ボタン
                        if error[:collector].present?
                          inner_html += content_tag(:button, I18n.t("cms.auto_correct.link"), type: "submit",
                            class: "btn btn-auto-correct",
                            name: "auto_correct"
                          )
                        end
                        inner_html.html_safe
                      end
                    end
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
