class Webmail::LoginController < ApplicationController
  include Webmail::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status]

  private

  def default_logged_in_path
    account = params[:account].try { |account| account.to_s }
    account ||= @cur_user.imap_default_index if @cur_user
    if account
      webmail_main_path(account: account)
    else
      webmail_main_path
    end
  end

  def get_params
    params.require(:item).permit(:uid, :email, :password, :encryption_type)
  rescue
    raise "400"
  end

  def login_path
    webmail_login_path
  end

  def logout_path
    webmail_logout_path
  end

  def mfa_login_path
    webmail_mfa_login_path
  end
end
