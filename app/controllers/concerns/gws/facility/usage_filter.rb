module Gws::Facility::UsageFilter
  extend ActiveSupport::Concern

  included do
    model Gws::Facility::Item

    navi_view "gws/main/conf_navi"
    menu_view 'gws/facility/usage/main/menu'

    helper_method :format_usage_count, :format_usage_hours

    before_action :set_target_time, :set_search_params, :set_years_and_months, :set_items
  end

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/facility.navi.usage'), { action: :index }]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_target_time
    @target_time ||= begin
      yyyy = params[:yyyy].presence
      yyyymm = params[:yyyymm].presence
      yyyymmdd = params[:yyyymmdd].presence
      raise '403' if yyyy.blank? && yyyymm.blank? && yyyymmdd.blank?

      if yyyy
        Time.zone.parse("#{yyyy}/01/01")
      elsif yyyymm
        Time.zone.parse("#{yyyymm[0..3]}/#{yyyymm[4..5]}/01")
      else
        Time.zone.parse("#{yyyymmdd[0..3]}/#{yyyymmdd[4..5]}/#{yyyymmdd[6..7]}")
      end
    end
  end

  def set_search_params
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s[:year] ||= @target_time.year
      s[:month] ||= @target_time.month if params[:yyyymm].present? || params[:yyyymmdd].present?
      s[:day] ||= @target_time.day if params[:yyyymmdd].present?
      s
    end
  end

  def find_usage(facility, *args)
    year, month, day = args
    @aggregation.find do |data|
      next false if data['_id']['facility_id'] != facility.id
      next false if data['_id']['year'] != year
      next false if data['_id']['month'] != month
      next false if day && data['_id']['day'] != day
      true
    end
  end

  def format_usage_count(*args)
    data = find_usage(*args)
    return unless data
    data['count'].to_s(:delimited)
  end

  def format_usage_hours(*args)
    data = find_usage(*args)
    return unless data
    data['total_usage_hours'].to_s
  end

  def set_years_and_months
    sy = Time.zone.today.year - 10 + 1
    ey = @cur_site.schedule_max_at.year
    @years = (sy..ey).to_a.reverse.map { |d| ["#{d}#{t('datetime.prompts.year')}", d] }
    @months = (1..12).to_a.map { |d| ["#{d}#{t('datetime.prompts.month')}", d] }
    sd = @target_time.day
    ed = @target_time.end_of_month.day
    @days = (sd..ed).lazy.map { |d| ["#{d}#{t('datetime.prompts.day')}", d] }
  end

  def set_items
    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site)
  end

  def target_range
    raise NotImplementedError
  end

  def aggregation_ids
    raise NotImplementedError
  end

  def aggregate
    criteria = Gws::Schedule::Plan.site(@cur_site).without_deleted
    criteria = criteria.in(facility_ids: @items.pluck(:id))
    criteria = criteria.gte(start_at: @target_time).lt(start_at: @target_time + target_range)

    @aggregation = Gws::Facility::UsageAggregator.new(criteria, aggregation_type).aggregate
  end

  def encode_sjis(str)
    str.encode("SJIS", invalid: :replace, undef: :replace)
  end

  public

  def index
    @items = @items.page(params[:page]).per(50)
    aggregate
  end
end
