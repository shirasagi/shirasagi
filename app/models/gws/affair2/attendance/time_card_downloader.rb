class Gws::Affair2::Attendance::TimeCardDownloader
  extend SS::Translation
  include ActiveModel::Model

  attr_accessor :site, :user, :time_card, :loader, :encoding

  delegate :format_time, :format_minutes, :format_minutes2, to: Gws::Affair2::Utils

  def initialize(time_card, loader, opts = {})
    @time_card = time_card
    @loader = loader
    @site = time_card.site
    @user = time_card.user
    @encoding = opts[:encoding]
  end

  def enum_csv
    Enumerator.new do |y|
      y << bom + encode(header.to_csv)
      loader.time_card_records.each do |date, record|
        line = []
        line << I18n.l(date.to_date) # 日付
        line << format_time(date, record.enter) # 出勤打刻
        line << format_time(date, record.leave) # 退勤打刻
        line << format_minutes(record.break_minutes) # 休憩時間
        line << loader.render_work_time(date) # 執務時間
        line << loader.render_over_time(date) # 時間外 執務時間
        line << loader.render_over_break_time(date) # 時間外 休憩等
        line << loader.render_over_compens(date) # 振替
        line << loader.render_leave(date) # 休暇
        line << record.memo # 備考
        y << encode(line.to_csv)
      end
    end
  end

  def header
    ["日付", "出勤打刻", "退勤打刻", "休憩時間", "執務時間", "時間外 執務時間", "時間外 休憩等", "振替", "休暇", "備考"]
  end

  private

  def encode(str)
    return str if encoding != "Shift_JIS"
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  def bom
    return '' if encoding == 'Shift_JIS'
    SS::Csv::UTF8_BOM
  end
end
