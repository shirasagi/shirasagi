class Gws::LoginController < ApplicationController
  include Gws::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status]
  before_action :set_organitzaion

  private

  def set_organitzaion
    @cur_site = SS::Group.organizations.where(domains: request_host).first || @cur_site
    raise '404' unless @cur_site
  end

  def default_logged_in_path
    gws_portal_path(site: @cur_site)
  end

  def get_params
    params.require(:item).permit(:uid, :email, :password, :encryption_type)
  rescue
    raise "400"
  end

  public

  def login
    if !request.post?
      # retrieve parameters from get parameter. this is bookmark support.
      @item = SS::User.new email: params[:email]
      return render(file: :login)
    end

    safe_params     = get_params
    email_or_uid    = safe_params[:email].presence || safe_params[:uid]
    password        = safe_params[:password]
    encryption_type = safe_params[:encryption_type]

    if encryption_type.present?
      password = SS::Crypt.decrypt(password, type: encryption_type) rescue nil
    end

    @item = SS::User.organization_authenticate(@cur_site, email_or_uid, password) rescue false
    @item = nil if @item && !@item.enabled?
    @item = @item.try_switch_user || @item if @item

    render_login @item, email_or_uid, session: true, password: password, logout_path: gws_logout_path(site: @cur_site)
  end
end
