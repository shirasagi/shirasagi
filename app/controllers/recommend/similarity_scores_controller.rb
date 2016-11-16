class Recommend::SimilarityScoresController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  model Recommend::SimilarityScore

  navi_view "recommend/main/navi"

  def index
    raise "403" unless @model.allowed?(:read, @cur_user, site: @cur_site)

    keyword = params.dig(:s, :keyword)
    cond = []
    cond << { :site_id => @cur_site.id }
    cond << { :created => { "$gte" => Time.zone.now.advance(days: -7) } }
    cond << { :key => /#{keyword}/ } if keyword.present?
    match = { "$and" => cond }

    @prefs = Recommend::SimilarityScore.to_key_axis_aggregation(match)
    @prefs = Kaminari.paginate_array(@prefs.to_a).page(params[:page]).per(10)
  end
end
