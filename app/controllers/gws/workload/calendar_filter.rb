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
    if params.dig("item", "api")
      set_item
      @year = @item.year
      return
    end

    # calendar add workload
    if params[:action] == "new" && @calendar_start && !params[:year].numeric?
      # カレンダーから遷移した際に年度を設定してリダイレクトする
      options = { action: "new", year: @cur_site.fiscal_year(@calendar_start) }.merge(request.query_parameters)
      redirect_to url_for(options)
      return
    end

    super
  end

  def crud_redirect_url
    calendar_redirect_url
  end

  public

  def calendar_redirect_url
    path = params.dig(:calendar, :path).to_s
    return if path.blank?
    return unless Sys::TrustedUrlValidator.myself_url?(path)

    uri = ::Addressable::URI.parse(path)
    uri.query = { calendar: redirection_calendar_params }.to_param
    uri.request_uri
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
