class Gws::Ldap::Diagnostic::AuthsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/diagnostic/navi"
  menu_view nil

  model SS::Ldap::LoginDiagnostic

  helper_method :ldap_setting

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

  def ldap_open(&block)
    config = ldap_setting.ldap_config
    config[:auth] = {
      method: :simple,
      username: @item.dn,
      password: @item.password
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

    @item.attributes = params.require(:item).permit(:dn, :password)
    if @item.invalid?
      render template: "show"
      return
    end

    ldap_open do |ldap|
      result = ldap.bind

      if result
        @results = [ "auth success" ]
      else
        @results = [ "auth failed" ]

        operation_result = ldap.get_operation_result
        @results << "#{operation_result.message}(#{operation_result.code})"
        if operation_result.error_message
          @results << operation_result.error_message
        end
      end
    end

    render template: "show"
  end
end
