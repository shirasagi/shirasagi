class Gws::LoginController < ApplicationController
  include HttpAcceptLanguage::AutoLocale
  include Gws::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status]

  private

  def set_organization
    @cur_organization ||= @cur_site
  end

  def default_logged_in_path
    gws_portal_path(site: @cur_site)
  end

  def get_params
    params.require(:item).permit(:uid, :email, :password, :encryption_type)
  rescue
    raise "400"
  end

  def logout_path
    gws_logout_path
  end

  def mfa_login_path
    gws_mfa_login_path
  end

  public

  def access_token
    token = SS::AccessToken.new(
      login_path: gws_login_path(site: @cur_site),
      logout_path: gws_logout_path(site: @cur_site),
      cur_user: @cur_user
    )
    token.create_token
    raise '403' unless token.save

    render plain: token.token
  end
end
