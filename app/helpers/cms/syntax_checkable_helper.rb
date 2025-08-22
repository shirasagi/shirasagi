module Cms::SyntaxCheckableHelper
  extend ActiveSupport::Concern
  include SS::MaterialIconsHelper

  def syntax_check_violation_count(item = nil)
    item ||= @item

    violation_count = item.try(:syntax_check_result_violation_count)
    violation_count ||= 0
    return if violation_count == 0

    title = t("cms.syntax_check_violation_count", count: violation_count, total: violation_count.to_fs(:delimited))
    md_icons.outlined("accessibility", class: "cms-syntax-check-violation-count", title: title, aria: { hidden: nil })
  end
end
