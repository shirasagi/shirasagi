module Cms::SyntaxCheckableHelper
  extend ActiveSupport::Concern
  include SS::MaterialIconsHelper

  def syntax_check_violation_count(site, item = nil)
    return unless site.syntax_check_enabled?

    item ||= @item
    return if !item.is_a?(Cms::SyntaxCheckResult)

    violation_count = item.syntax_check_result_violation_count || 0
    return if violation_count == 0

    title = t("cms.syntax_check_violation_count", count: violation_count, total: violation_count.to_fs(:delimited))
    md_icons.outlined("accessibility", class: "cms-syntax-check-violation-count", title: title, aria: { hidden: nil })
  end
end
