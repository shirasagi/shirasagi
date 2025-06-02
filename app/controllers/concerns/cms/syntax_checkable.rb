module Cms::SyntaxCheckable
  extend ActiveSupport::Concern

  private

  def syntax_check
    contents = build_syntax_check_contents

    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)
    if @syntax_checker.errors.present?
      @syntax_checker.errors.each do |error|
        @item.errors.add :base, error[:msg]
      end
      return false
    end
    true
  end

  def build_syntax_check_contents
    contents = [{ "id" => "html", "content" => @item.html, "resolve" => "html", "type" => "scalar" }]

    # ブロック入力（カラム値）もcontentsに追加
    if @item.respond_to?(:column_values)
      @item.column_values.each_with_index do |column_value, idx|
        value =
          if column_value.respond_to?(:in_wrap) && column_value.in_wrap.present?
            column_value.in_wrap
          elsif column_value.respond_to?(:value)
            column_value.value
          else
            nil
          end
        next if value.blank?
        contents << {
          "id" => "column_#{idx}",
          "content" => value,
          "resolve" => "html",
          "type" => "scalar"
        }
      end
    end
    contents
  end

  def auto_correct
    error_index = params[:auto_correct].to_i
    @item.errors.clear

    # 構文チェックを実行
    contents = [{ "id" => "html", "content" => @item.html, "resolve" => "html", "type" => "scalar" }]
    @syntax_checker = Cms::SyntaxChecker.check(cur_site: @cur_site, cur_user: @cur_user, contents: contents)

    before_html = @item.html
    @syntax_checker.errors.each_with_index do |error, idx|
      next unless idx == error_index
      next unless error[:collector].present?

      Rails.logger.debug("[auto_correct] 修正前HTML: #{before_html.inspect}")

      case error[:collector]
      when "Cms::SyntaxChecker::InterwordSpaceChecker"
        content_html = error[:code]
      else
        content_html = @item.html
      end

      corrected = Cms::SyntaxChecker.correct(
        cur_site: @cur_site,
        cur_user: @cur_user,
        content: {
          "content" => content_html,
          "resolve" => "html",
          "type" => "scalar"
        },
        collector: error[:collector],
        params: (error[:collector_params] || {}).transform_keys(&:to_s)
      )

      next unless corrected.respond_to?(:result)
      corrected_html = corrected.result

      Rails.logger.debug("[auto_correct] 修正後HTML: #{corrected_html.inspect}")

      case error[:collector]
      when "Cms::SyntaxChecker::InterwordSpaceChecker"
        @item.html = replace_html(before_html, error[:code], corrected_html)
      else
        @item.html = corrected_html
      end
    end
  end

  def replace_html(before_html, error_code, corrected_html)
    pattern = Regexp.new(Regexp.escape(error_code))
    replaced_text = before_html.gsub(/#{pattern}/, corrected_html)
    replaced_text
  end
end
