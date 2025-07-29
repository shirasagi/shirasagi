class Cms::Apis::YoutubeController < ApplicationController
  protect_from_forgery except: :fetch_title

  def fetch_title
    url = params[:url]
    youtube_id = Cms::Column::Value::Youtube.get_youtube_id(url)
    if youtube_id.blank?
      render json: { error: "invalid url" }, status: :bad_request and return
    end

    value = Cms::Column::Value::Youtube.new(url: url, youtube_id: youtube_id)
    value.fetch_youtube_title
    render json: { title: value.title }
  rescue => e
    render json: { error: e.message }, status: :bad_request
  end
end
