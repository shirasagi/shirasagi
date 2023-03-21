class Gws::DailyReport::UserReportEnumerator < Enumerator
  def initialize(site, user, group, month, reports, encoding: "UTF-8")
    @cur_site = site
    @cur_user = user
    @cur_group = group
    @cur_month = month
    @reports = reports.dup
    @encoding = encoding

    super() do |yielder|
      load_forms
      build_term_handlers

      yielder << bom + encode(headers.to_csv)
      (@cur_month.beginning_of_month.to_date..@cur_month.end_of_month.to_date).each do |date|
        enum_report(yielder, date, @reports.and_date(date).first)
      end
    end
  end

  private

  def load_forms
    if @reports.is_a?(Mongoid::Criteria)
      form_ids = @reports.pluck(:form_id).uniq
    else
      form_ids = @reports.map { |report| report.form_id }.uniq
    end

    @base_form_use = form_ids.include?(nil)
    @forms = Gws::DailyReport::Form.site(@cur_site).in(id: form_ids.compact).order_by(order: 1, created: 1)
    # load all forms in memory for performance
    @forms = @forms.to_a

    return if @forms.present?

    @forms = Gws::DailyReport::Form.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      in(daily_report_group_id: @cur_group.id).
      where(year: @cur_site.fiscal_year).
      order_by(order: 1, created: 1).
      to_a
  end

  def build_term_handlers
    @handlers = []
    if Gws::DailyReport::Report.allowed?(:access, @cur_user, site: @cur_site)
      @handlers << { name: Gws::DailyReport::Report.t(:limited_access), handler: method(:to_limited_access), type: :base }
    end
    @handlers << { name: Gws::DailyReport::Report.t(:small_talk), handler: method(:to_small_talk), type: :base }
    @forms.each do |form|
      form.columns.order_by(order: 1).each do |column|
        @handlers << {
          name: column.name,
          handler: method(:to_column_value).curry.call(form, column),
          type: :base
        }
      end
    end
  end

  def headers
    header = []
    header << I18n.t('gws/daily_report.date')
    header << I18n.t('gws/daily_report.wday')
    header << @handlers.pluck(:name)
    header.flatten
  end

  def enum_report(yielder, date, report)
    row = []
    row << I18n.l(date, format: :short)
    row << I18n.t("date.abbr_day_names")[date.wday]
    row << base_infos(report)
    yielder << encode(row.flatten.to_csv)
  end

  def base_infos(report)
    @handlers.map do |handler|
      if handler[:type] == :base
        next unless report

        handler[:handler].call(report)
      else
        nil
      end
    end
  end

  def to_limited_access(report)
    report.limited_access
  end

  def to_small_talk(report)
    text = []
    if report.share_small_talk.present?
      text << I18n.t('gws/daily_report.shared')
      text << report.small_talk
      report.column_comments('small_talk').each do |comment|
        text << "#{comment.body}(#{comment.user.try(:name)})"
      end
    elsif report.manageable?(@cur_user, site: @cur_site, date: @cur_month)
      text << report.small_talk
      report.column_comments('small_talk').each do |comment|
        text << "#{comment.body}(#{comment.user.try(:name)})"
      end
    end
    text.join("\n")
  end

  def to_column_value(form, column, report)
    return nil if form.id != report.form_id

    column_value = report.column_values.where(column_id: column.id).first
    return nil if column_value.blank?

    text = []
    if report.share_column_ids.include?(column.id.to_s)
      text << I18n.t('gws/daily_report.shared')
      text << column_value.value
      report.column_comments(column.id).each do |comment|
        text << "#{comment.body}(#{comment.user.try(:name)})"
      end
    elsif report.manageable?(@cur_user, site: @cur_site, date: @cur_month)
      text << column_value.value
      report.column_comments(column.id).each do |comment|
        text << "#{comment.body}(#{comment.user.try(:name)})"
      end
    end
    text.join("\n")
  end

  def encode(str)
    return '' if str.blank?

    str = str.encode('CP932', invalid: :replace, undef: :replace) if @encoding == 'Shift_JIS'
    str
  end

  def bom
    return '' if @encoding == 'Shift_JIS'
    "\uFEFF"
  end
end
