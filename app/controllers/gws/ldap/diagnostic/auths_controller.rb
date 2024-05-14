class Gws::Ldap::Diagnostic::AuthsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/diagnostic/navi"
  menu_view nil

  model SS::Ldap::LoginDiagnostic

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("sys.diag"), gws_ldap_diagnostic_main_path]
    @crumbs << ["Auth", url_for(action: :show)]
  end

  def set_item
    @item = @model.new
  end

  def ldap_setting
    @ldap_setting ||= begin
      if @cur_site.ldap_use_state_system?
        Sys::Auth::Setting.instance
      else
        @cur_site
      end
    end
  end

  def ldap_url
    ldap_setting.ldap_url
  end

  def ldap_openssl_verify_mode
    ldap_setting.ldap_openssl_verify_mode
  end

  public

  def show
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)

    if ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render
      return
    end

    render
  end

  def update
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)

    @item.attributes = params.require(:item).permit(:dn, :password)
    if @item.invalid?
      render template: "show"
      return
    end

    result = ::Ldap::Connection.authenticate(
      url: ldap_url, openssl_verify_mode: ldap_openssl_verify_mode, username: @item.dn, password: @item.password)
    if result
      @result = "success"
    else
      @result = "failed"
    end

    render template: "show"
  end
end
