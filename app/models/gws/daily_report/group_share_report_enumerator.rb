class Gws::DailyReport::GroupShareReportEnumerator < Gws::DailyReport::Enumerator::Base
  def initialize(site, user, reports, options)
    @cur_site = site
    @cur_user = user
    @cur_group = options[:group]
    @cur_month = options[:month]
    @reports = reports.dup
    @encoding = options[:encoding].presence || "UTF-8"
    @export_target = options[:export_target].presence || 'all'

    super() do |yielder|
      load_forms
      build_term_handlers

      yielder << bom
      (@cur_month.beginning_of_month.to_date..@cur_month.end_of_month.to_date).each do |date|
        enum_reports(yielder, date, @reports.and_date(date))
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

  def enum_reports(yielder, date, reports)
    row = []
    row << I18n.l(date, format: :short)
    row << I18n.t("date.abbr_day_names")[date.wday]
    reports.each do |report|
      row << base_infos(report).select(&:present?)
    end
    yielder << encode(row.flatten.to_csv)
  end

  def to_small_talk(report)
    text = []
    if report.share_small_talk.present?
      text << report.user.try(:name)
      text << "【#{report.t(:small_talk)}】"
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
      text << report.user.try(:name)
      text << "【#{column.try(:name)}】"
      text << column_value.value
      report.column_comments(column.id).each do |comment|
        text << "#{comment.body}(#{comment.user.try(:name)})"
      end
    end
    text.join("\n")
  end
end
