class Recommend::History::ReceiverController < ApplicationController

  before_action :set_site

  public
    def index
      token = cookies["_ss_recommend"]
      path = params[:path]
      access_url = params[:access_url]
      target_id = params[:target_id]
      target_class = params[:target_class]
      remote_addr = request.env["HTTP_X_REAL_IP"] || request.remote_ip
      user_agent = request.user_agent

      if token && !Recommend::History::Log.site(@cur_site).where(token: token).first
        token = nil
      end

      log = Recommend::History::Log.new(
        token: token, site: @cur_site,
        path: path, access_url: access_url,
        target_id: target_id, target_class: target_class,
        remote_addr: remote_addr, user_agent: user_agent,
      )
      log.save

      cookies.permanent["_ss_recommend"] = log.token

      respond_to do |format|
        format.json { render json: log.attributes.to_json }
      end
    end

  private
    def set_site
      @cur_site = Cms::Site.find id: params[:site]
    end
end
