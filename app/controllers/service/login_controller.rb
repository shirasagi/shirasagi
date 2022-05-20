class Service::LoginController < ApplicationController
  include Service::BaseFilter
  include Service::LoginFilter

  model Service::Account
  layout "service/login"
  navi_view nil

  skip_before_action :logged_in?, only: [:login]

  private

  def get_params
    params.require(:item).permit(:account, :password)
  rescue
    raise "400"
  end

  public

  def login
    return unless request.post?

    safe_params = get_params
    account     = safe_params[:account].to_s.presence
    password    = safe_params[:password].to_s.presence

    @item = @model.authenticate(account, password) rescue false
    @item = nil if @item && !@item.enabled?

    render_login @item, account, session: true, password: password
  end

  def logout
    # discard all session info
    reset_session if SS.config.sns.logged_in_reset_session
    respond_to do |format|
      format.html { redirect_to service_login_path }
      format.json { head :no_content }
    end
  end
end
