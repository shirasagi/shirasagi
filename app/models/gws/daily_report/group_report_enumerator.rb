class Gws::DailyReport::GroupReportEnumerator < Enumerator
  def initialize(site, user, group, reports, options)
    @cur_site = site
    @cur_user = user
    @cur_group = group
    @reports = reports.dup
    @encoding = options[:encoding].presence || "UTF-8"
    @export_target = options[:export_target].presence || 'all'
    users = Gws::User.site(@cur_site).where(group_ids: @cur_group.id)
    if @cur_site.fiscal_year(@reports.first.try(:daily_report_date).presence || Time.zone.now) != @cur_site.fiscal_year
      users = users.where(id: @cur_user.id)
    end

    super() do |yielder|
      load_forms
      build_term_handlers

      yielder << bom + encode(headers.to_csv)
      users.each do |user|
        enum_report(yielder, user, @reports.and_user(user).first)
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
      where(year: @cur_site.fiscal_year, daily_report_group_id: @cur_group.id).
      order_by(order: 1, created: 1).
      to_a
  end

  def build_term_handlers
    @handlers = []
    if Gws::DailyReport::Report.allowed?(:access, @cur_user, site: @cur_site) && @export_target == 'all'
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
    header << Gws::User.t(:name)
    header << @handlers.pluck(:name)
    header.flatten
  end

  def enum_report(yielder, user, report)
    row = []
    row << user.name
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
    elsif report.manageable?(@cur_user, site: @cur_site, date: @cur_month) && @export_target == 'all'
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
    elsif report.manageable?(@cur_user, site: @cur_site, date: @cur_month) && @export_target == 'all'
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
