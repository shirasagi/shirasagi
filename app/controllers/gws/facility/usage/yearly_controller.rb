class Gws::Facility::Usage::YearlyController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::UsageFilter

  navi_view "gws/schedule/main/navi"

  private

  def target_range
    1.year
  end

  def aggregation_ids
    {
      'facility_id' => '$facility_ids',
      'year' => { '$year' => '$local_start_at' },
      'month' => { '$month' => '$local_start_at' }
    }
  end

  public

  def download
    filename = "facility_#{@target_time.year}_usage"
    filename = "#{filename}_#{Time.zone.now.to_i}.csv"

    enum = Enumerator.new do |y|
      y << encode_sjis([@model.t(:name), I18n.t('gws/facility.usage.type'), *@months.map { |month| month[0] }].to_csv)
      aggregate
      @items.each do |item|
        terms = []
        terms << item.name
        terms << I18n.t('gws/facility.usage.hours')
        @months.each do |month|
          terms << format_usage_hours(item, @target_time.year, month[1])
        end
        y << encode_sjis(terms.to_csv)

        terms.clear
        terms << item.name
        terms << I18n.t('gws/facility.usage.times')
        @months.each do |month|
          terms << format_usage_count(item, @target_time.year, month[1])
        end
        y << encode_sjis(terms.to_csv)
      end
    end

    response.status = 200
    send_enum enum, type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
