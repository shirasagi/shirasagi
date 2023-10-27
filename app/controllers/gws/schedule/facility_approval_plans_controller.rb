class Gws::Schedule::FacilityApprovalPlansController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Schedule::PlanFilter

  model Gws::Schedule::Plan

  navi_view "gws/schedule/main/navi"

  helper_method :approval_state_options

  private

  def set_crumbs
    @crumbs << [@cur_site.menu_schedule_label || t('modules.gws/schedule'), gws_schedule_main_path]
    @crumbs << [t("gws/schedule.navi.approve_facility_plan"), { action: :index }]
  end

  def fix_params
    { cur_user: @cur_user, cur_site: @cur_site }
  end

  def set_items
    set_approval_facilities
    @items = @model.site(@cur_site).without_deleted.
      in(facility_ids: @approval_facilities.pluck(:id))
  end

  def set_approval_facilities
    @approval_facilities = Gws::Facility::Item.site(@cur_site).
      where(approval_check_state: 'enabled').
      in(user_ids: @cur_user.id).
      active
  end

  def redirection_url
    url_for(action: :index)
  end

  public

  def index
    approval_state = params.dig(:s, :approval_state)
    approval_state = "request" if approval_state.blank?

    @items = @items.where(approval_state: approval_state).
      search(params[:s]).
      reorder(start_at: -1).
      page(params[:page]).
      per(50)
  end

  def soft_delete_all
    raise "400" if @selected_items.blank?

    entries = @selected_items.entries
    @items = []

    entries.each do |item|
      if item.allowed?(:delete, @cur_user, site: @cur_site)
        item.attributes = fix_params
        item.record_timestamps = false
        item.deleted = Time.zone.now
        item.edit_range = "one"
        next if item.save
      else
        item.errors.add :base, :auth_error
      end
      @items << item
    end
    render_confirmed_all(entries.size != @items.size)
  end
end
