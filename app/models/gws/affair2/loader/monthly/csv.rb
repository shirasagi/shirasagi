class Gws::Affair2::Loader::Monthly::Csv < Gws::Affair2::Loader::Monthly::Base

  delegate :format_time, :format_minutes, :format_minutes2, to: Gws::Affair2::Utils

  def render_work_time(date)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return format_minutes(nil)
    end

    record = time_card_records[date]

    # タイムカードが打刻されているか
    if !record.entered?
      return format_minutes(nil)
    end

    format_minutes(load_records[date].work_minutes2)
  end

  # --:--
  # --:-- ( 結果を入力 [命令] )
  # --:-- ( 1:00 [命令] | -1:00 )
  # --:-- ( 1:00 [確認] | -1:00 )
  def render_over_time(date)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return format_minutes(nil)
    end

    record = time_card_records[date]

    over_minutes1 = load_records[date].work_overtime_minutes
    over_minutes2 = load_records[date].overtime_minutes
    diff_minutes = over_minutes1 - over_minutes2

    # タイムカードが打刻されているか
    label1 = record.entered? ? format_minutes(over_minutes1) : format_minutes(nil)

    # 時間外が申請されているか
    effective_records = overtime_records[record.date]
    if effective_records.blank?
      return label1
    end

    if effective_records.all?(&:confirmed?)
      # 結果確認済み
      label2 = format_minutes(over_minutes2)
      label3 = "[確認]"
      link = label2 + label3
      if diff_minutes >= 0
        label4 = format_minutes2(diff_minutes)
      else
        label4 = format_minutes2(diff_minutes)
      end
    elsif effective_records.all?(&:entered?)
      # 結果入力済み
      label2 = format_minutes(over_minutes2)
      label3 = "[命令]"
      link = label2 + label3

      if diff_minutes >= 0
        label4 = format_minutes2(diff_minutes)
      else
        label4 = format_minutes2(diff_minutes)
      end
    else
      # 結果未入力
      label2 = "結果を入力"
      label3 = "[命令]"
      label4 = nil
      link = label2 + label3
    end

    h = []
    h << label1
    h << " ( "
    h << link
    if label4
      h << " | "
      h << label4
    end
    h <<  " )"
    h.join
  end

  def render_over_break_time(date)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    record = time_card_records[date]

    # タイムカードが打刻されているか
    if !record.entered?
      return format_minutes(nil)
    end

    over_minutes1 = load_records[date].work_overtime_minutes
    over_minutes2 = load_records[date].overtime_minutes

    diff_minutes = over_minutes1 - over_minutes2
    diff_minutes = 0 if diff_minutes < 0

    format_minutes(diff_minutes)
  end

  def render_over_compens(date)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    record = time_card_records[date]

    # 振替があるか
    effective_records = overtime_records[record.date].to_a
    effective_records = effective_records.select { |r| r.holiday? }
    effective_records = effective_records.select(&:compens?)
    return nil if effective_records.blank?

    effective_records.map do |record|
      I18n.l(record.compens_date.to_date, format: :m_d_a)
    end.join("\n")
  end

  def render_leave(date)
    # タイムカードに所定時間が設定されているか
    if time_card.nil? || !time_card.regular_open?
      return nil
    end

    record = time_card_records[date]

    # 休暇があるか
    effective_records = leave_records[record.date].to_a
    return nil if effective_records.blank?

    h = []
    effective_records.each do |record|
      h << record.name
    end
    h.join("\n")
  end
end
