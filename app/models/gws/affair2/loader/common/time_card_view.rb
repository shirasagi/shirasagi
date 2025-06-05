module Gws::Affair2::Loader::Common::TimeCardView
  extend ActiveSupport::Concern

  included do
    attr_accessor :view_context

    delegate :format_time, :format_minutes, :format_minutes2, to: Gws::Affair2::Utils
    delegate :editable?, :time_card_forms_path, :link_to, to: :view_context
  end

  def render_work_time(date, time_card, time_card_record, load_record)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return format_minutes(nil)
    end

    # タイムカードが打刻されているか
    if time_card_record.nil? || !time_card_record.entered?
      return format_minutes(nil)
    end

    format_minutes(load_record.work_minutes2)
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # --:--
  # --:-- ( 結果を入力 [命令] )
  # --:-- ( 1:00 [命令] | -1:00 )
  # --:-- ( 1:00 [確認] | -1:00 )
  def render_over_time(date, time_card, time_card_record, load_record, overtime_records)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return format_minutes(nil)
    end

    over_minutes1 = load_record.work_overtime_minutes
    over_minutes2 = load_record.overtime_minutes
    diff_minutes = over_minutes1 - over_minutes2

    # タイムカードが打刻されているか
    if time_card_record && time_card_record.entered?
      label1 = format_minutes(over_minutes1)
    else
      label1 = format_minutes(nil)
    end

    # 時間外が申請されているか
    if overtime_records.blank?
      return label1
    end

    if overtime_records.all?(&:confirmed?)
      # 結果確認済み
      label2 = format_minutes(over_minutes2)
      label3 = "[確認]"
      if diff_minutes >= 0
        label4 = "<span class=\"overtime-diff plus\">#{format_minutes2(diff_minutes)}</span>"
      else
        label4 = "<span class=\"overtime-diff minus\">#{format_minutes2(diff_minutes)}</span>"
      end
      link = label2 + label3
    elsif overtime_records.all?(&:entered?)
      # 結果入力済み
      label2 = format_minutes(over_minutes2)
      label3 = "[命令]"
      if diff_minutes >= 0
        label4 = "<span class=\"overtime-diff plus\">#{format_minutes2(diff_minutes)}</span>"
      else
        label4 = "<span class=\"overtime-diff minus\">#{format_minutes2(diff_minutes)}</span>"
      end
      if editable?(time_card)
        link = link_to(
          label2 + label3,
          time_card_forms_path(:overtime_records, :edit, id: time_card, day: date.day),
          { class: "edit-overtime-records" })
      else
        link = label2 + label3
      end
    else
      # 結果未入力
      label2 = "結果を入力"
      label3 = "[命令]"
      label4 = nil
      if editable?(time_card)
        link = link_to(
          label2 + label3,
          time_card_forms_path(:overtime_records, :edit, id: time_card, day: date.day),
          { class: "edit-overtime-records" })
      else
        link = label2 + label3
      end
    end

    h = []
    h << label1
    h << " ( "
    h << link
    if label4
      h << " | "
      h << label4
    end
    h << " )"
    h.join.html_safe
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/PerceivedComplexity

  def render_over_break_time(date, time_card, time_card_record, load_record)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    # タイムカードが打刻されているか
    if time_card_record.nil? || !time_card_record.entered?
      return format_minutes(nil)
    end

    over_minutes1 = load_record.work_overtime_minutes
    over_minutes2 = load_record.overtime_minutes

    diff_minutes = over_minutes1 - over_minutes2
    diff_minutes = 0 if diff_minutes < 0

    format_minutes(diff_minutes).html_safe
  end

  def render_over_compens(date, time_card, time_card_record, load_record, overtime_records)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    # 振替があるか
    return nil if overtime_records.blank?

    overtime_records = overtime_records.select { |r| r.holiday? && r.compens? }
    return nil if overtime_records.blank?

    overtime_records.map do |record|
      I18n.l(record.compens_date.to_date, format: :m_d_a)
    end.join("<br>").html_safe
  end

  def render_leave(date, time_card, time_card_record, load_record, leave_records)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    # 休暇があるか
    return nil if leave_records.blank?

    h = []
    leave_records.each do |record|
      if time_card.unlocked?
        link = link_to(
          record.name,
          time_card_forms_path(:leave_records, :edit, id: time_card, day: date.day),
          { class: "edit-leave-records" })
      else
        link = record.name
      end
      h << link
    end
    h.join("<br>").html_safe
  end
end
