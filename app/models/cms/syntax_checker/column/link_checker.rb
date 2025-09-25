class Cms::SyntaxChecker::Column::LinkChecker
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base

  attr_accessor :context, :content, :column_value, :attribute, :params

  def check
    return unless parsed_params

    main_check
    after_check
  end

  private

  def main_check
    value = column_value.link_label
    value = value.freeze
    fragment = Nokogiri::HTML5.fragment(value || "")
    fragment = fragment.freeze

    work_context = context.with(html: value, fragment: fragment)
    work_content = content.with(content: value, resolve: "text", type: "string")

    checkers = Cms::SyntaxChecker.text_checkers
    checkers.each do |checker|
      innstance = checker.new
      innstance.check(work_context, work_content)
    end
  end

  # LinkCheck.prototype.afterCheck = function (id, content) {
  #   var text = content["content"];
  #   if (text && text.length <= 3) {
  #     Syntax_Checker.errors.push({
  #       id: id, idx: 0, code: text,
  #       msg: Syntax_Checker.message["checkLinkText"],
  #       detail: Syntax_Checker.detail["checkLinkText"]
  #     });
  #   }
  # };
  def after_check
    text = column_value.link_label
    return if text.blank? # blank is safe

    if context.link_text_min_length > 0 && text.length < context.link_text_min_length # greater than 3 is safe
      error = I18n.t("errors.messages.link_text_too_short", count: context.link_text_min_length)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, checker: self, code: text, error: error)
    end
  end
end
