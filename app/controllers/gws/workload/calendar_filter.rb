module Gws::Workload::CalendarFilter
  extend ActiveSupport::Concern
  include Gws::Schedule::CalendarFilter::Transition

  included do
    helper Gws::Schedule::PlanHelper
    helper_method :calendar_redirect_url
  end

  private

  def set_calendar_start
    @calendar_start = Date.parse(params[:start]) rescue nil
  end

  def set_year
    set_calendar_start

    # calendar drop
    if params.dig("item","api")
      set_item
      @year = @item.year
      return
    end

    # calendar add workload
    if params[:action] == "new" && @calendar_start
      # カレンダーから遷移した際に年度を設定してリダイレクトする
      if !params[:year].match?(/\A\d+\z/)
        redirect_to({ year: @cur_site.fiscal_year(@calendar_start) }.merge(request.query_parameters))
        return
      end
    end

    super
  end

  def crud_redirect_url
    calendar_redirect_url
  end

  public

  def calendar_redirect_url
    @calendar_redirect_url ||= begin
      path = params.dig(:calendar, :path)
      return nil if path.blank?
      uri = URI(path)
      uri.query = { calendar: redirection_calendar_params }.to_param
      uri.to_s
    end
  end

  def popup
    set_item

    if @item.readable?(@cur_user, site: @cur_site)
      render template: "popup", layout: false
    else
      render template: 'gws/schedule/plans/popup_hidden', layout: false
    end
  end
end
