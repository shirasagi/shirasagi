module Cms::SyntaxChecker::Base
  extend ActiveSupport::Concern

  def check(context, id, idx, raw_html, doc)
  end

  def correct(context)
  end
end
