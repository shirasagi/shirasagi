module Cms::SyntaxChecker::Base
  extend ActiveSupport::Concern

  class << self
    def each_html_with_index(content, &block)
      content = content["content"]
      Array(content).each_with_index do |value, index|
        value = value.strip
        # 'value' must be wrapped with "<div>"
        value = "<div>#{value}</div>" if !value.start_with?("<div>")

        yield value, index
      end
    end

    def each_text_node(fgrament)
      fgrament.traverse do |node|
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
  end

  def check(context, id, idx, raw_html, fragment)
  end

  def correct(context)
  end
end
