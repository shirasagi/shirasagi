class Cms::SyntaxChecker::AreaAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('area').each do |area_node|
      alt = area_node["alt"]
      alt = alt.strip if alt
      next if alt.present?

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(area_node),
        msg: I18n.t('errors.messages.set_area_alt'),
        detail: I18n.t('errors.messages.syntax_check_detail.set_area_alt')
      }
    end
  end
end
