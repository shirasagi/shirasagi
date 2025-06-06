module Gws::Affair2::TimeCardHelper
  extend ActiveSupport::Concern

  # 本日（午前3時〜翌日午前3時）
  ## enter, leave 打刻可能、編集権限があれば編集可能（なければ不可）
  ## memo, break_minutes 常に編集可能
  # 他日
  ## enter, leave 打刻不可、編集権限があれば編集可能（なければ不可）
  ## memo, break_minutes 編集権限があれば編集可能（なければ不可）

  def render_punchable(item, record, field_name, &block)
    mode = "none"
    if punchable?(item) && record.find_latest_history(field_name).blank? && attendance_date?(record.date)
      mode = "punch"
    elsif editable?(item)
      mode = "edit"
    end
    url = time_card_forms_path(field_name, mode, id: item, day: record.date.day) if mode != "none"
    capture(mode, url, &block)
  end

  def render_editable(item, record, field_name, &block)
    mode = "none"
    if punchable?(item) && attendance_date?(record.date)
      mode = "edit"
    elsif editable?(item)
      mode = "edit"
    end
    url = time_card_forms_path(field_name, mode, id: item, day: record.date.day) if mode != "none"
    capture(mode, url, &block)
  end

  def render_reason(record, field_name)
    history = record.find_latest_history(field_name)
    return if history.nil?
    return if history.reason.blank?

    tag.div(class: "reason-tooltip") do
      '<i class="material-icons md-13">&#xE0C9;</i>'.html_safe +
        tag.div(class: "reason") do
          tag.div { history.reason } + ss_time_tag(history.created)
        end
    end
  end
end
