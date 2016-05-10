module Sns::LoginFilter
  extend ActiveSupport::Concern

  private
    def login_success
      if params[:ref].blank?
        redirect_to SS.config.sns.logged_in_page
      elsif params[:ref] =~ /^\//
        redirect_to params[:ref]
      else
        render "sns/login/redirect"
      end
    end

    def render_login(user, email_or_uid, opts = {})
      alert = opts.delete(:alert).presence || t("sns.errors.invalid_login")

      if user
        opts[:session] ||= true
        set_user user, opts
        respond_to do |format|
          format.html { login_success }
          format.json { head :no_content }
        end
      else
        @item = SS::User.new
        @item.email = email_or_uid if email_or_uid.present?
        respond_to do |format|
          flash[:alert] = alert
          format.html { render "sns/login/login" }
          format.json { render json: alert, status: :unprocessable_entity }
        end
      end
    end
end
