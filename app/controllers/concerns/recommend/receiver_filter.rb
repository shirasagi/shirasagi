module Recommend::ReceiverFilter
  extend ActiveSupport::Concern

  def index
    token = cookies["_ss_recommend"]
    path = params[:path]
    access_url = params[:access_url]
    target_id = params[:target_id]
    target_class = params[:target_class]
    user_agent = request.user_agent

    if token && !Recommend::History::Log.site(@cur_site).where(token: token).first
      token = nil
    end

    log = Recommend::History::Log.new(
      token: token, site: @cur_site,
      path: path, access_url: access_url,
      target_id: target_id, target_class: target_class,
      remote_addr: remote_addr, user_agent: user_agent
    )
    log.save if log.class.enable_access_logging?(@cur_site)

    cookie_value = { value: log.token, http_only: true }
    cookie_value[:same_site] = SS.config.ss.session["same_site"] if !SS.config.ss.session["same_site"].nil?
    cookie_value[:secure] = SS.config.ss.session["secure"] if !SS.config.ss.session["secure"].nil?

    cookies.permanent["_ss_recommend"] = cookie_value

    head :ok
  end
end
