module Service::LoginFilter
  extend ActiveSupport::Concern

  private

  def render_login(user, account, opts = {})
    alert = opts.delete(:alert).presence || t("service.errors.invalid_login")

    if user
      opts[:session] ||= true
      set_user(user, opts)

      respond_to do |format|
        format.html { redirect_to(service_main_path) }
        format.json { head :no_content }
      end
    else
      @item = @model.new
      @item.account = account if account.present?

      respond_to do |format|
        flash[:alert] = alert
        format.html { render }
        format.json { render json: alert, status: :unprocessable_entity }
      end
    end
  end
end
