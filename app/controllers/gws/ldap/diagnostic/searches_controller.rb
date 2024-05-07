require 'net/ldap/dn'

class Gws::Ldap::Diagnostic::SearchesController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/diagnostic/navi"
  menu_view nil

  model SS::Ldap::SearchDiagnostic

  helper_method :ldap_setting

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("sys.diag"), gws_ldap_diagnostic_main_path]
    @crumbs << ["Search", url_for(action: :show)]
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

  def ldap_open(&block)
    config = ldap_setting.ldap_config
    config[:auth] = {
      method: :simple,
      username: @item.user_dn,
      password: @item.user_password
    }

    Net::LDAP.open(config, &block)
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

    @item.attributes = params.require(:item).permit(:user_dn, :user_password, :base_dn, :scope, :filter)
    if @item.invalid?
      render template: "show"
      return
    end

    # user_dn = Net::LDAP::DN.new(@item.user_dn)
    base_dn = Net::LDAP::DN.new(@item.base_dn)
    if @item.scope.present?
      scope = Net::LDAP.const_get("SearchScope_#{@item.scope.classify}")
    else
      scope = Net::LDAP::SearchScope_WholeSubtree
    end
    filter = Net::LDAP::Filter.construct(@item.filter)

    ldap_open do |ldap|
      @entries = ldap.search(base: base_dn, scope: scope, filter: filter, size: Gws::Ldap::MAX_SEARCH_RESULTS)
    end

    render template: "show"
  end
end
