class Cms::SyntaxChecker::Column::EditorChecker
  include ActiveModel::Model
  include Cms::SyntaxChecker::Column::Base

  attr_accessor :context, :content, :column_value, :attribute, :params

  def check
    return unless parsed_params

    value = column_value[attribute]
    value = value.freeze

    fragment = Nokogiri::HTML5.fragment(value || "")
    fragment = fragment.freeze

    work_context = context.with(html: value, fragment: fragment)
    work_content = content.with(content: value, resolve: "html", type: "string")

    checkers = Cms::SyntaxChecker.html_checkers
    checkers.each do |checker|
      innstance = checker.new
      innstance.check(work_context, work_content)
    end
  end
end
