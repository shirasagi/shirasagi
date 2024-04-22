class Cms::LoginController < ApplicationController
  include Cms::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status]

  private

  def set_organization
    # users never logs in to group in cms login controller.
    @cur_organization = nil
  end

  def default_logged_in_path
    cms_contents_path(site: @cur_site)
  end

  def get_params
    params.require(:item).permit(:uid, :email, :password, :encryption_type)
  rescue
    raise "400"
  end

  def login_path
    cms_login_path
  end

  def logout_path
    cms_logout_path
  end

  def mfa_login_path
    cms_mfa_login_path
  end
end
