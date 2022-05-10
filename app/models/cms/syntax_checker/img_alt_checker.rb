class Cms::SyntaxChecker::ImgAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('img').each do |img_node|
      alt = img_node["alt"]
      alt = alt.strip if alt
      if alt.blank?
        context.errors << {
          id: id,
          idx: idx,
          code: Cms::SyntaxChecker::Base.outer_html_summary(img_node),
          msg: I18n.t('errors.messages.set_img_alt'),
          detail: I18n.t('errors.messages.syntax_check_detail.set_img_alt')
        }

        next
      end

      src = img_node["src"]
      src = src.strip if src
      next if src.blank? || !src.downcase.include?(alt.downcase)

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(img_node),
        msg: I18n.t('errors.messages.alt_is_included_in_filename'),
        detail: I18n.t('errors.messages.syntax_check_detail.alt_is_included_in_filename')
      }
    end
  end
end
