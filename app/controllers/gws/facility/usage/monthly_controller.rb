class Gws::Facility::Usage::MonthlyController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::UsageFilter

  navi_view "gws/schedule/main/navi"

  private

  def target_range
    1.month
  end

  def aggregation_type
    :month
  end

  public

  def download
    filename = "facility_#{@target_time.year}#{'%02d' % @target_time.month}_usage"
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    enum = Enumerator.new do |y|
      y << encode_sjis([@model.t(:name), I18n.t('gws/facility.usage.type'), *@days.map { |day| day[0] }].to_csv)
      aggregate
      @items.each do |item|
        terms = []
        terms << item.name
        terms << I18n.t('gws/facility.usage.hours')
        @days.each do |day|
          terms << format_usage_hours(item, @target_time.year, @target_time.month, day[1])
        end
        y << encode_sjis(terms.to_csv)

        terms.clear
        terms << item.name
        terms << I18n.t('gws/facility.usage.times')
        @days.each do |day|
          terms << format_usage_count(item, @target_time.year, @target_time.month, day[1])
        end
        y << encode_sjis(terms.to_csv)
      end
    end

    response.status = 200
    send_enum enum, type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
