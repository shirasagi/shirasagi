module Cms::SyntaxChecker::Base
  extend ActiveSupport::Concern

  class << self
    def outer_html_summary(node)
      node.to_s.gsub(/[\r\n]|&nbsp;/, "")
    end
  end

  def check(context, id, idx, raw_html, doc)
  end

  def correct(context)
  end
end
