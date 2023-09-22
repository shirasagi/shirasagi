class Cms::SyntaxChecker::OrderOfHChecker
  include Cms::SyntaxChecker::Base

  H_TAGS = %w(h1 h2 h3 h4 h5 h6).freeze

  def check(context, id, idx, raw_html, fragment)
    code = ''
    h_nodes = fragment.css(H_TAGS.join(","))
    h_nodes.each_with_index do |current_node, i|
      prev_node = i > 0 ? h_nodes[i - 1] : nil

      current_level = h_level(current_node)
      prev_level = h_level(prev_node) if prev_node

      if i == 0
        # first leve of h should be 1 or 2
        if current_level <= 2 && !context.header_check
          context.h_level_check = current_level
          context.header_check = true 
        elsif (current_level > 2  && !context.header_check) || (context.h_level_check < current_level - 1)
          code += current_node.name + " "
        else
          context.h_level_check = current_level
        end
      elsif current_level <= 2
        # 2 個目以降にある h1, h2 は無チェック
        next
      elsif prev_level < current_level - 1
        code += current_node.name + " "
      end
    end
    return if code.blank?

    context.errors << {
      id: id,
      idx: idx,
      code: code.strip,
      msg: I18n.t('errors.messages.invalid_order_of_h'),
      detail: I18n.t('errors.messages.syntax_check_detail.invalid_order_of_h'),
      collector: self.class.name
    }
  end

  def correct(context)
    ret = []

    Cms::SyntaxChecker::Base.each_html_with_index(context.content) do |html, index|
      fragment = Nokogiri::HTML5.fragment(html)
      h_nodes = fragment.css(H_TAGS.join(","))
      h_nodes.each_with_index do |current_node, i|
        prev_node = i > 0 ? h_nodes[i - 1] : nil

        current_level = h_level(current_node)
        prev_level = h_level(prev_node) if prev_node

        if i == 0
          # first leve of h should be 1 or 2
          if current_level > 2
            current_node.name = "h1"
          end
        elsif current_level <= 2
          # 2 個目以降にある h1, h2 は無チェック
          next
        elsif prev_level < current_level - 1
          current_node.name = prev_level <= 2 ? "h2" : "h#{prev_level}"
        end
      end

      ret << Cms::SyntaxChecker::Base.inner_html_within_div(fragment)
    end

    context.set_result(ret)
  end

  private

  def h_level(node)
    H_TAGS.index(node.name.downcase) + 1
  end
end
