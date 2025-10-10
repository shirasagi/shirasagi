module Cms::SyntaxCheckResult
  extend ActiveSupport::Concern
  extend SS::Translation

  included do
    # アクセシビリティチェック実施日時
    field :syntax_check_result_checked, type: DateTime
    # アクセシビリティ違反件数
    field :syntax_check_result_violation_count, type: Integer
  end

  def set_syntax_check_result(syntax_checker_context)
    return unless self.persisted?
    return unless syntax_checker_context

    violation_count = syntax_checker_context.errors.select { _1.id.present? }.count
    self.set(
      syntax_check_result_checked: Time.zone.now.utc,
      syntax_check_result_violation_count: violation_count
    )
  end
end
