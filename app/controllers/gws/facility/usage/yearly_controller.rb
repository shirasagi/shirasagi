class Gws::Facility::Usage::YearlyController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  model Gws::Facility::Item

  navi_view 'gws/facility/settings/navi'
  menu_view 'gws/facility/usage/main/menu'

  helper_method :format_usage_count, :format_usage_hours

  private

  def set_crumbs
    @crumbs << [t('mongoid.models.gws/facility/group_setting'), gws_facility_items_path]
    @crumbs << [t('gws/facility.navi.usage'), gws_facility_usage_yearly_index_path]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_target_time
    @target_time ||= begin
      yyyy = params[:yyyy].presence
      raise '403' if yyyy.blank?

      Time.zone.parse("#{yyyy}/01/01")
    end
  end

  def set_search_params
    set_target_time
    @s ||= begin
      s = OpenStruct.new(params[:s])
      s[:year] ||= @target_time.year
      s
    end
  end

  def find_usage(facility, year, month)
    @aggregation.find do |data|
      data['_id']['facility_id'] == facility.id && data['_id']['month'] == month
    end
  end

  def format_usage_count(facility, year, month)
    data = find_usage(facility, year, month)
    return unless data
    count = data['count']
    count.to_s(:delimited)
  end

  def format_usage_hours(facility, year, month)
    data = find_usage(facility, year, month)
    return unless data
    hours = data['total_usage_hours']
    hours.to_s
  end

  public

  def index
    set_target_time
    set_search_params

    sy = Time.zone.today.year - 10
    ey = Time.zone.today.year
    @years = (sy..ey).to_a.reverse.map { |d| ["#{d}#{t('datetime.prompts.year')}", d] }
    @months = (1..12).to_a.map { |d| ["#{d}#{t('datetime.prompts.month')}", d] }

    @items = @model.site(@cur_site).
      state(params.dig(:s, :state)).
      search(params[:s]).
      allow(:read, @cur_user, site: @cur_site).
      page(params[:page]).per(50)

    criteria = Gws::Schedule::Plan.site(@cur_site)
    criteria = criteria.in(facility_ids: @items.pluck(:id))
    criteria = criteria.gte(start_at: @target_time).lt(start_at: @target_time + 1.year)

    pipes = []
    pipes << { '$match' => criteria.selector }
    pipes << {
      '$project' => {
        'usage_hours' => { '$subtract' => [ '$end_at', '$start_at' ] },
        'facility_ids' => 1,
        'start_at' => { '$add' => [ '$start_at', Time.zone.utc_offset * 1_000 ] },
        'end_at' => { '$add' => [ '$end_at', Time.zone.utc_offset * 1_000 ] }
      }
    }
    pipes << {
      '$project' => {
        'usage_hours' => { '$cond' => [ { '$gte' => [ '$usage_hours', 86_399_000 ] }, 24 * 60 * 60 * 1_000, '$usage_hours' ] },
        'facility_ids' => 1,
        'start_at' => 1,
        'end_at' => 1
      }
    }
    pipes << { '$unwind' => '$facility_ids' }
    pipes << {
      '$group' => {
        '_id' => {
          'facility_id' => '$facility_ids',
          'year' => { '$year' => '$start_at' },
          'month' => { '$month' => '$start_at' }
        },
        'count' => { '$sum' => 1 },
        'total_usage_hours' => { '$sum' => { '$divide' => [ '$usage_hours', 60 * 60 * 1_000 ] } }
      }
    }

    @aggregation = Gws::Schedule::Plan.collection.aggregate(pipes).to_a.map(&:to_h)
  end
end
