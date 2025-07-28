class Gws::Apis::FacilitiesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Facility::Item

  before_action :set_category
  before_action :set_plan, if: ->{ params[:item].present? }
  before_action :set_time_search, if: ->{ params[:item].present? }
  before_action :set_hour_range, if: ->{ @plan && @time_search && @free_times }

  private

  def category_criteria
    Gws::Facility::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def set_category
    @categories = category_criteria.tree_sort

    category_id = params.dig(:s, :category)
    if category_id
      @category = category_criteria.find(category_id) rescue nil
    end
  end

  def category_ids
    return category_criteria.pluck(:id) + [nil] if @category.blank?
    ids = category_criteria.where(name: /^#{::Regexp.escape(@category.name)}\//).pluck(:id)
    ids << @category.id
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def pre_params
    { min_hour: @cur_site.facility_min_hour || 8, max_hour: @cur_site.facility_max_hour || 22 }
  end

  def set_plan
    item_params = params[:item].to_unsafe_h
    item_params.delete(:facility_column_values)
    item_id = item_params[:id]

    if item_id.present?
      @plan = Gws::Schedule::Plan.find(item_id)
      @plan.attributes = item_params
    else
      @plan = Gws::Schedule::Plan.new item_params
    end
    @plan.cur_user = @cur_user
    @plan.cur_site = @cur_site

    @plan.user_id = @cur_user.id
    @plan.site_id = @cur_site.id

    @plan
  end

  def set_time_search
    @time_search = Gws::Schedule::PlanSearch.new(
      pre_params.merge(params.require(:s).permit(Gws::Schedule::PlanSearch.permitted_fields).merge(fix_params))
    )
    @time_search.facility_ids = @model.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      reservable(@cur_user).
      active.pluck(:id)
    @time_search.valid?
    @free_times = @time_search.search

    @time_search
  end

  def set_hour_range
    @hour_range = {}
    between_days = (@plan.end_at.to_date - @plan.start_at.to_date).to_i

    return set_hour_range_a_day_plan if between_days == 0
    return set_hour_range_repeat_plan if @plan.repeat?
    set_hour_range_repeat_plan
  end

  def set_hour_range_a_day_plan
    params_min_hour = params.dig(:d, :min_hour).presence
    params_max_hour = params.dig(:d, :max_hour).presence

    @free_times.each do |date, hours|
      min_hour = params_min_hour || @cur_site.facility_min_hour || 8
      max_hour = params_max_hour || @cur_site.facility_max_hour || 22
      @hour_range[date] = (min_hour.to_i...max_hour.to_i)
    end

    @hour_range
  end

  def set_hour_range_repeat_plan
    params_min_hour = params.dig(:d, :min_hour).presence
    params_max_hour = params.dig(:d, :max_hour).presence
    between_days = (@plan.end_at.to_date - @plan.start_at.to_date).to_i

    @free_times.each do |date, hours|
      repeat_start = date
      repeat_end = date.advance(days: between_days)

      (repeat_start..repeat_end).each do |d|
        min_hour = @cur_site.facility_min_hour || 8
        max_hour = @cur_site.facility_max_hour || 22

        if (repeat_start == d) && params_min_hour
          min_hour = params_min_hour
        end
        if (repeat_end == d) && params_max_hour
          max_hour = params_max_hour
        end

        if @hour_range[d]
          exist_min = @hour_range[d].first
          exist_max = @hour_range[d].last

          min_hour = (exist_min < min_hour.to_i) ? exist_min : min_hour.to_i
          max_hour = (exist_max > max_hour.to_i) ? exist_max : max_hour.to_i
        end

        @hour_range[d] = (min_hour.to_i...max_hour.to_i)
      end
    end

    @hour_range
  end

  def set_hour_range_plan
    params_min_hour = params.dig(:d, :min_hour).presence
    params_max_hour = params.dig(:d, :max_hour).presence

    @free_times.each do |date, hours|
      min_hour = @cur_site.facility_min_hour || 8
      max_hour = @cur_site.facility_max_hour || 22

      if (@time_search.start_on == date) && params_min_hour
        min_hour = params_min_hour
      end
      if (@time_search.end_on == date) && params_max_hour
        max_hour = params_max_hour
      end
      @hour_range[date] = (min_hour.to_i...max_hour.to_i)
    end

    @hour_range
  end

  public

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      reservable(@cur_user).
      active.
      search(params[:s])
    @items = @items.in(category_id: category_ids)
    @items = @items.page(params[:page]).per(50)
  end
end
