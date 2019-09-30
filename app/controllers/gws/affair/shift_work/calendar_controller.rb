class Gws::Affair::ShiftWork::CalendarController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter
  include Gws::Attendance::TimeCardFilter

  model Gws::Affair::ShiftRecord

  menu_view nil

  navi_view "gws/affair/main/navi"

  append_view_path 'app/views/gws/affair/shift_work/calendar'

  before_action :set_active_year_range
  before_action :set_cur_month
  before_action :set_groups
  before_action :set_user, only: :shift_record

  helper_method :year_month_options, :group_options
  helper_method :next_month, :prev_month
  helper_method :editable_shift_record?

  private

  def fix_params
    {}
  end

  def set_crumbs
    @crumbs << [@cur_site.menu_affair_label || t('modules.gws/affair'), gws_affair_main_path]
    @crumbs << [t("modules.gws/affair/shift_work/calendar"), gws_affair_shift_work_calendar_path]
  end

  def set_user
    @user = Gws::User.find(params[:user]) rescue nil
  end

  def set_groups
    if @model.allowed?(:manage_all, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_site).active
    elsif @model.allowed?(:manage_private, @cur_user, site: @cur_site)
      @groups = Gws::Group.in_group(@cur_group).active
    else
      @groups = Gws::Group.none
    end

    @group = @groups.to_a.select { |group| group.id == params[:group_id].to_i }.first
    @group ||= @cur_group
  end

  def editable_shift_record?
    %i[manage_private manage_all].find { |priv| Gws::Affair::ShiftRecord.allowed?(priv, @cur_user, site: @cur_site) }
  end

  def year_month_options
    options = []
    date = @active_year_range.last
    while date >= @active_year_range.first
      options << [l(date.to_date, format: :attendance_year_month), "#{date.year}#{format('%02d', date.month)}"]
      date -= 1.month
    end
    options
  end

  def next_month
    @next_month ||= begin
      date = @cur_month.advance(months: 1)
      if date > @active_year_range.last
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), group_id: @group.id })
      end
    end
  end

  def prev_month
    @prev_month ||= begin
      date = @cur_month.advance(months: -1)
      if date < @active_year_range.first
        false
      else
        url_for({ action: :index, year_month: date.strftime('%Y%m'), group_id: @group.id })
      end
    end
  end

  def group_options
    @groups.map { |g| [g.name, g.id] }
  end

  public

  def index
    set_groups

    #シフト勤務カレンダーがあるユーザーのみ
    user_ids = Gws::Affair::ShiftCalendar.site(@cur_site).pluck(:user_id)
    @users = Gws::User.active.in(group_ids: [@group.id]).in(id: user_ids).order_by_title(@cur_site)
  end

  def shift_record
    raise "403" unless editable_shift_record?

    @cur_date = @cur_month.change(day: params[:day])
    @shift_calendar = @user.shift_calendar(@cur_site)

    @item = @shift_calendar.shift_record(@cur_date) || @model.new
    @item.shift_calendar_id = @shift_calendar.id
    @item.date = @cur_date

    if request.get?
      render template: 'shift_record', layout: false
      return
    end

    @item.attributes = get_params
    if @item.valid?

      if @item.same_default?
        @item.destroy
      else
        @item.save
      end

      location = params[:ref].presence || url_for(action: :index)
      notice = t('ss.notice.saved')

      respond_to do |format|
        flash[:notice] = notice
        format.html do
          if request.xhr?
            render json: { location: location }, status: :ok, content_type: json_content_type
          else
            redirect_to location
          end
        end
        format.json { render json: { location: location }, status: :ok, content_type: json_content_type }
      end
    else
      respond_to do |format|
        format.html { render template: 'shift_record', layout: false, status: :unprocessable_entity }
        format.json { render json: @cell.errors.full_messages, status: :unprocessable_entity, content_type: json_content_type }
      end
    end
  end
end
