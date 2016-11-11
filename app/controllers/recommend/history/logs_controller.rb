class Recommend::History::LogsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Recommend::History::Log

  navi_view "recommend/main/navi"
  menu_view "recommend/main/menu"

  def tokens
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    keyword = params.dig(:s, :keyword)
    cond = []
    cond << { :site_id => @cur_site.id }
    cond << { :created => { "$gte" => Time.zone.now.advance(days: -7) } }
    cond << { :token => /#{keyword}/ } if keyword.present?
    match = { "$and" => cond }

    @prefs = Recommend::History::Log.to_token_axis_aggregation(match)
    @prefs = Kaminari.paginate_array(@prefs.to_a).page(params[:page]).per(10)

    render :index
  end

  def paths
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    keyword = params.dig(:s, :keyword)
    cond = []
    cond << { :site_id => @cur_site.id }
    cond << { :created => { "$gte" => Time.zone.now.advance(days: -7) } }
    cond << { :path => /#{keyword}/ } if keyword.present?
    match = { "$and" => cond }

    @prefs = Recommend::History::Log.to_path_axis_aggregation(match)
    @prefs = Kaminari.paginate_array(@prefs.to_a).page(params[:page]).per(10)

    render :index
  end
end
