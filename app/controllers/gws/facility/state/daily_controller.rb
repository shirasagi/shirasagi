class Gws::Facility::State::DailyController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Facility::UsageFilter

  navi_view "gws/schedule/main/navi"
  menu_view 'gws/facility/state/main/menu'

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t('gws/facility.navi.state'), { action: :index }]
  end

  def facility_category_criteria
    Gws::Facility::Category.site(@cur_site).readable(@cur_user, site: @cur_site)
  end

  def category_ids
    facility_category_id = params.dig(:s, :category)
    return [] if facility_category_id.blank?

    @facility_category = facility_category_criteria.find(facility_category_id) rescue nil
    return [] if @facility_category.blank?

    ids = facility_category_criteria.where(name: /^#{::Regexp.escape(@facility_category.name)}\//).pluck(:id)
    ids << @facility_category.id
  end

  def set_items
    @facilities = Gws::Facility::Item.site(@cur_site).
      active.
      readable(@cur_user, site: @cur_site).
      in(category_id: category_ids.presence).
      reorder(name: 1).
      entries

    @plans = Gws::Schedule::Plan.site(@cur_site).without_deleted.
      between_dates(@target_time, @target_time + 1.day).
      any_in(facility_ids: @facilities.map(&:id))

    @items = @facilities.map do |facility|
      plans = @plans.select { |plan| plan.facility_ids.include?(facility.id) }
      if plans.present?
        OpenStruct.new(name: facility.name, plans: plans)
      else
        nil
      end
    end.compact
  end

  public

  def index
    render
  end

  def download
    filename = "facility_#{@target_time.strftime('%Y%m%d')}_state_#{Time.zone.now.to_i}.csv"
    fields = %w(facility start_at end_at section user purpose)
    field_names = fields.map { |m| I18n.t("gws/facility.state.#{m}") }

    enum = Enumerator.new do |y|
      y << encode_sjis(field_names.to_csv)

      @items.each do |item|
        item.plans.each do |plan|
          cols = []
          cols << item.name
          cols << I18n.l(plan.start_at, format: :gws_long)
          cols << I18n.l(plan.end_at, format: :gws_long)
          cols << plan.section_name
          cols << plan.user.try(:name)

          if plan.readable?(@cur_user, site: @cur_site)
            cols << plan.name
          else
            cols << I18n.t("gws/schedule.private_plan")
          end
          y << encode_sjis(cols.to_csv)
        end
      end
    end

    response.status = 200
    send_enum enum, type: 'text/csv; charset=Shift_JIS', filename: filename
  end
end
