class Cms::SyntaxChecker::ImgDataUriSchemeChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('img[src]').each do |img_node|
      src = img_node['src']
      next if !src.start_with?('data:')

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(img_node),
        msg: I18n.t('errors.messages.invalid_img_scheme'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_img_scheme')
      }
    end
  end
end
