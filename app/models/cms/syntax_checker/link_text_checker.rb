class Cms::SyntaxChecker::LinkTextChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css("a[href]").each do |a_node|
      text = a_node.text
      if text.length <= 3
        img_node = a_node.at_css("img[alt]")
        if img_node
          text = img_node["alt"]
        end
      end
      text = text.strip if text
      next if text.length > 3

      code = Cms::SyntaxChecker::Base.outer_html_summary(a_node)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :check_link_text)
    end
  end
end
