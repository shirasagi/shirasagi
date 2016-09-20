class Recommend::History::ReceiverController < ApplicationController

  before_action :set_site

  private
    def set_site
      @cur_site = Cms::Site.find id: params[:site]
    end

  public
    def index
      token = cookies["_ss_recommend"]
      path = params[:path]
      url = params[:url]

      if token && !Recommend::History::Log.site(@cur_site).where(token: token).first
        token = nil
      end

      url = params[:url]
      log = Recommend::History::Log.new(path: path, url: url, token: token, site: @cur_site)
      log.save

      cookies.permanent["_ss_recommend"] = log.token

      respond_to do |format|
        format.json { render json: log.attributes.to_json }
      end
    end
end
