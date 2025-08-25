module Cms::SyntaxChecker::LinkTextSetting
  extend ActiveSupport::Concern
  extend SS::Translation

  DEFAULT_SYNTAX_CHECKER_LINK_TEXT_MIN_LENGTH = 4

  included do
    field :syntax_checker_link_text_min_length, type: Integer, default: DEFAULT_SYNTAX_CHECKER_LINK_TEXT_MIN_LENGTH
    validates :syntax_checker_link_text_min_length, numericality: { greater_than_or_equal_to: 0 }
  end
end
