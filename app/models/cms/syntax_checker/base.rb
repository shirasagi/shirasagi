module Cms::SyntaxChecker::Base
  extend ActiveSupport::Concern

  class << self
    def each_html_with_index(content, &block)
      Array(content.content).each_with_index do |value, index|
        value = value.strip
        # 'value' must be wrapped with "<div>"
        value = "<div>#{value}</div>" if !value.start_with?("<div>")

        yield value, index
      end
    end

    def each_text_node(fragment)
      fragment.traverse do |node|
        if node.text?
          yield node
        end
      end
    end

    def inner_html_within_div(doc)
      div = doc.at('div')
      return doc.inner_html.strip if !div

      div.inner_html.strip
    end

    def outer_html_summary(node)
      node.to_s.gsub(/[\r\n]|&nbsp;|\u00a0/, "")
    end

    def extract_a11y_label(context, node)
      if node.key?("aria-labelledby")
        aria_labelled_by = node["aria-labelledby"]
        if aria_labelled_by.present?
          return context.fragment.css("##{aria_labelled_by}").text
        else
          return
        end
      end

      if node.key?("aria-label")
        return node["aria-label"]
      end

      text_parts = []
      img_elements = node.css("[aria-labelledby],[aria-label],[alt],[title]")
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

      return node.text if node.text.present?

      node["title"]
    end
  end

  def check(context, id, idx, raw_html, fragment)
  end

  def correct(context)
  end

  def correct2(content, params: nil)
  end
end
