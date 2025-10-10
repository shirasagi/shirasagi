class Cms::SyntaxChecker::LinkTextChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css("a[href]").each do |a_node|
      code = Cms::SyntaxChecker::Base.outer_html_summary(a_node)

      text = extract_link_text(context, a_node)
      if text
        text = text.strip
      else
        text = ""
      end

      check_unfavorable_word(context, content, text, code)
      check_length(context, content, text, code)
    end
  end

  private

  def extract_link_text(context, a_node)
    if a_node.key?("aria-labelledby")
      aria_labelled_by = a_node["aria-labelledby"]
      if aria_labelled_by.present?
        return context.fragment.css("##{aria_labelled_by}").text
      else
        return
      end
    end

    if a_node.key?("aria-label")
      return a_node["aria-label"]
    end

    text_parts = []
    img_elements = a_node.css("[aria-labelledby],[aria-label],[alt],[title]")
    img_elements.each do |img_element|
      if img_element.key?("aria-labelledby")
        aria_labelled_by = img_element["aria-labelledby"]
        if aria_labelled_by.present?
          aria_labelled_by_elment = context.fragment.css("##{aria_labelled_by}")
          if aria_labelled_by_elment
            text_parts << aria_labelled_by_elment.text
          end
        end
        next
      end

      if img_element.key?("aria-label")
        text_parts << img_element["aria-label"]
        next
      end

      if img_element.key?("alt")
        text_parts << img_element["alt"]
        next
      end

      if img_element.key?("title")
        text_parts << img_element["title"]
        next
      end
    end

    text_parts.compact!
    if text_parts.present?
      return text_parts.join(" ")
    end

    return a_node.text if a_node.text.present?

    a_node["title"]
  end

  def check_unfavorable_word(context, content, text, code)
    return if text.blank?
    return unless context.include_unfavorable_word?(text)

    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: :unfavorable_word)
  end

  def check_length(context, content, text, code)
    return if text.blank?
    return if context.link_text_min_length <= 0
    return if text.length >= context.link_text_min_length

    error = I18n.t("errors.messages.link_text_too_short", count: context.link_text_min_length)
    context.errors << Cms::SyntaxChecker::CheckerError.new(
      context: context, content: content, code: code, checker: self, error: error)
  end
end
