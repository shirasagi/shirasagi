class Gws::DailyReport::ReportEnumerator < Gws::DailyReport::Enumerator::Base
  def initialize(site, user, reports, options)
    @cur_site = site
    @cur_user = user
    @reports = reports.dup
    @encoding = options[:encoding].presence || "UTF-8"
    @export_target = options[:export_target].presence || 'all'

    super() do |yielder|
      load_forms
      build_term_handlers

      yielder << bom + encode(headers.to_csv)
      @reports.each do |report|
        enum_report(yielder, report)
      end
    end
  end

  private

  def build_term_handlers
    @handlers = []

    @handlers << { name: Gws::DailyReport::Report.t(:name), handler: method(:to_name), type: :base }
    if Gws::DailyReport::Report.allowed?(:access, @cur_user, site: @cur_site)
      @handlers << { name: Gws::DailyReport::Report.t(:limited_access), handler: method(:to_limited_access), type: :base }
    end
    @handlers << { name: Gws::DailyReport::Report.t(:small_talk), handler: method(:to_small_talk), type: :base }
    if @base_form_use
      @handlers << { name: Gws::DailyReport::Report.t(:html), handler: method(:to_html), type: :base }
      @handlers << { name: Gws::DailyReport::Report.t(:file_ids), handler: method(:to_files), type: :base }
    end

    @forms.each do |form|
      form.columns.order_by(order: 1).each do |column|
        @handlers << {
          name: "#{form.name}/#{column.name}",
          handler: method(:to_column_value).curry.call(form, column),
          type: :base
        }
      end
    end

    @handlers << { name: Gws::DailyReport::Report.t(:updated), handler: method(:to_updated), type: :base }
  end

  def headers
    @handlers.pluck(:name)
  end

  def enum_report(yielder, report)
    yielder << encode(base_infos(report).to_csv)
  end

  def to_name(report)
    report.name
  end

  def to_limited_access(report)
    report.limited_access
  end

  def to_small_talk(report)
    report.small_talk
  end

  def to_html(report)
    return nil if report.form_id.present?

    report.html
  end

  def to_files(report)
    filenames = []

    SS::File.in(id: report.file_ids).each do |file|
      filenames << file.humanized_name
    end

    filenames.join("\n")
  end

  def to_column_value(form, column, report)
    return nil if form.id != report.form_id

    column_value = report.column_values.where(column_id: column.id).first
    return nil if column_value.blank?

    column_value.value
  end

  def to_updated(report)
    I18n.l(report.updated)
  end
end
