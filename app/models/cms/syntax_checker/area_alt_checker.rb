class Cms::SyntaxChecker::AreaAltChecker
  include Cms::SyntaxChecker::Base

  def check(context, content)
    context.fragment.css('area').each do |area_node|
      alt = area_node["alt"]
      alt = alt.strip if alt
      next if alt.present?

      code = Cms::SyntaxChecker::Base.outer_html_summary(area_node)
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: content, code: code, checker: self, error: :set_area_alt)
    end
  end
end
