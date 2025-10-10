class Cms::SyntaxChecker::UnfavorableWordsChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    Cms::SyntaxChecker::Base.each_text_node(context.fragment) do |text_node|
      text = text_node.content.strip
      if context.include_unfavorable_word?(text)
        context.errors << Cms::SyntaxChecker::CheckerError.new(
          context: context, content: content, code: text, checker: self, error: :unfavorable_word)
      end
    end
  end
end
