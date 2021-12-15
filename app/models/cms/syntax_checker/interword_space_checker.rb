class Cms::SyntaxChecker::InterwordSpaceChecker
  include Cms::SyntaxChecker::Base

  FULL_WIDTH_SPACE = '　'.freeze

  def check(context, id, idx, raw_html, fragment)
    Cms::SyntaxChecker::Base.each_text_node(fragment) do |text_node|
      text = text_node.content.strip
      next if !text.include?(FULL_WIDTH_SPACE)

      context.errors << {
        id: id,
        idx: idx,
        code: text,
        msg: I18n.t('errors.messages.check_interword_space'),
        detail: I18n.t('errors.messages.syntax_check_detail.check_interword_space')
      }
    end
  end
end
