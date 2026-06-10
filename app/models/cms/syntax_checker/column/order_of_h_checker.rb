class Cms::SyntaxChecker::Column::OrderOfHChecker
  include ActiveModel::Model

  attr_accessor :context, :contents

  def check
    code_first = ''
    code_skip = ''
    first_content_for_first = nil
    first_content_for_skip = nil
    h_level_check = context.h_level_check
    header_check = context.header_check

    headline_contents.each_with_index do |current_content, i|
      prev_content = i > 0 ? headline_contents[i - 1] : nil

      current_level = h_level(current_content)
      prev_level = h_level(prev_content) if prev_content

      if i == 0
        # first leve of h should be 1 or 2
        if current_level <= 2 && !header_check
          h_level_check = current_level
          header_check = true
        elsif current_level > 2 && !header_check
          code_first += current_content.column_value.head + " "
          first_content_for_first ||= current_content
        elsif h_level_check < current_level - 1
          code_skip += current_content.column_value.head + " "
          first_content_for_skip ||= current_content
        else
          h_level_check = current_level
        end
      elsif current_level <= 2
        # 2 個目以降にある h1, h2 は無チェック
        next
      elsif prev_level < current_level - 1
        code_skip += current_content.column_value.head + " "
        first_content_for_skip ||= current_content
      end
    end

    if code_first.present?
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: first_content_for_first, code: code_first.strip, checker: self,
        error: :invalid_first_heading_level)
    end
    if code_skip.present?
      context.errors << Cms::SyntaxChecker::CheckerError.new(
        context: context, content: first_content_for_skip, code: code_skip.strip, checker: self,
        error: :invalid_heading_level_skip)
    end
  end

  private

  def headline_contents
    @headline_contents ||= contents.select { _1.column_value.is_a?(Cms::Column::Value::Headline) }
  end

  def h_level(content)
    Cms::SyntaxChecker::OrderOfHChecker::H_TAGS.index(content.column_value.head.downcase) + 1
  end
end
