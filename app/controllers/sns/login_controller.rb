class Sns::LoginController < ApplicationController
  include Sns::BaseFilter
  include Sns::LoginFilter

  skip_before_action :logged_in?, only: [:login, :remote_login, :status, :redirect]

  layout "ss/login"
  navi_view nil

  private

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

    @item = begin
      if @cur_organization
        SS::User.organization_authenticate(@cur_organization, email_or_uid, password) rescue nil
      else
        SS::User.authenticate(email_or_uid, password) rescue nil
      end
    end
    @item = nil if @item && (@item.disabled? || @item.locked?)
    @item = @item.try_switch_user || @item if @item

    render_login @item, email_or_uid, session: true, password: password
  end

  def remote_login
    raise "404" unless SS::config.sns.remote_login

    login
    render :login if response.body.blank?
  end

  def status
    if @cur_user = get_user_by_session
      render plain: 'OK'
    else
      raise '403'
    end
  end
end
