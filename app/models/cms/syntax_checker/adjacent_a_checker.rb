class Cms::SyntaxChecker::AdjacentAChecker
  include Cms::SyntaxChecker::Base

  def check(context, id, idx, raw_html, fragment)
    fragment.css('a[href]').each do |a_node|
      next_node = a_node.next_element
      next if !next_node || !next_node.name.casecmp("a").zero?
      next if a_node["href"] != next_node["href"]

      context.errors << {
        id: id,
        idx: idx,
        code: Cms::SyntaxChecker::Base.outer_html_summary(a_node) + Cms::SyntaxChecker::Base.outer_html_summary(next_node),
        msg: I18n.t('errors.messages.invalid_adjacent_a'),
        detail: I18n.t('errors.messages.syntax_check_detail.invalid_adjacent_a'),
        collector: self.class.name
      }
    end
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)

      nodes = []
      fragment.css('a[href]').each do |a_node|
        next_node = a_node.next_element
        next if !next_node || !next_node.name.casecmp("a").zero?
        next if a_node["href"] != next_node["href"]

        nodes << [ a_node, next_node ]
      end
      nodes.reverse_each do |prev_node, next_node|
        if prev_node.inner_html != next_node.inner_html
          prev_node.add_child next_node.children
        end
        next_node.remove
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end
end
