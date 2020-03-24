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

    @item = SS::User.authenticate(email_or_uid, password) rescue false
    @item = nil if @item && !@item.enabled?
    @item = @item.try_switch_user || @item if @item
    @cur_user = @item

    render_login @item, email_or_uid, session: true, password: password, logout_path: webmail_logout_path
  end
end
