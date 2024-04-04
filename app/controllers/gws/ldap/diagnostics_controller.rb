class Gws::Ldap::DiagnosticsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/main/navi"
  menu_view nil

  model SS::Ldap::LoginDiagnostic

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("sys.diag"), url_for(action: :show)]
  end

  def set_item
    @item = @model.new
  end

  def ldap_url
    if @cur_site.ldap_use_state_system?
      url = Sys::Auth::Setting.instance.ldap_url
    else
      url = @cur_site.ldap_url
    end
    url
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

    result = ::Ldap::Connection.authenticate(url: ldap_url, username: @item.dn, password: @item.password)
    if result
      @result = "success"
    else
      @result = "failed"
    end

    render template: "show"
  end
end
