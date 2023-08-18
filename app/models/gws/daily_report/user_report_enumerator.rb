class Gws::DailyReport::UserReportEnumerator < Gws::DailyReport::Enumerator::Base
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
    if Gws::DailyReport::Report.allowed?(:access, @cur_user, site: @cur_site) ||
       @reports.first.try(:user_id) == @cur_user.id
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
end
