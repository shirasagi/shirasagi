class Cms::SyntaxChecker::ImgAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('img').each do |img_node|
      alt = img_node["alt"]
      alt = alt.strip if alt
      if alt.blank?
        code = Cms::SyntaxChecker::Base.outer_html_summary(img_node)
        context.errors << Cms::SyntaxChecker::CheckerError.new(
          context: context, content: content, code: code, checker: self, error: :set_img_alt)

        next
      end

      src = img_node["src"]
      src = src.strip if src
      next if src.blank? || !src.downcase.include?(alt.downcase)

      code = Cms::SyntaxChecker::Base.outer_html_summary(img_node)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :alt_is_included_in_filename)
    end
  end
end
