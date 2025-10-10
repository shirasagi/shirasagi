class Cms::SyntaxChecker::ImgDataUriSchemeChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('img[src]').each do |img_node|
      src = img_node['src']
      next if !src.start_with?('data:')

      code = Cms::SyntaxChecker::Base.outer_html_summary(img_node)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :invalid_img_scheme)
    end
  end
end
