class Gws::DailyReport::Enumerator::Base < Enumerator

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
