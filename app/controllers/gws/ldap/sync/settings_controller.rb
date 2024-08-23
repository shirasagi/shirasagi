class Gws::Ldap::Sync::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/sync/main/navi"

  model Gws::Ldap::SyncTask

  before_action :check_ldap_url, only: %i[show]

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("ldap.buttons.sync"), gws_ldap_sync_main_path]
    @crumbs << [t("ldap.setting"), url_for(action: :show)]
  end

  def set_item
    @item ||= Gws::Ldap::SyncTask.where(group_id: @cur_site).reorder(id: 1).first_or_create
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

  def check_ldap_url
    if ldap_setting.ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render
      return
    end
  end

  public

  def test_connection
    set_item

    if ldap_setting.ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render layout: false
      return
    end

    result = ::Ldap::Connection.authenticate(
      url: ldap_setting.ldap_url, openssl_verify_mode: ldap_setting.ldap_openssl_verify_mode,
      username: @item.admin_dn, password: SS::Crypto.decrypt(@item.admin_password))
    if result
      @result = "success"
    else
      @result = "failed"
    end

    render layout: false
  end

  def group_test_search
    set_item

    if ldap_setting.ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render layout: false
      return
    end

    if @item.group_scope.present?
      scope = Net::LDAP.const_get("SearchScope_#{@item.group_scope.classify}")
    else
      scope = Net::LDAP::SearchScope_WholeSubtree
    end

    config = ldap_setting.ldap_config
    config[:auth] = {
      method: :simple,
      username: @item.admin_dn,
      password: SS::Crypto.decrypt(@item.admin_password)
    }

    Net::LDAP.open(config) do |ldap|
      filter = Net::LDAP::Filter.construct(@item.group_filter)
      @result = ldap.search(base: @item.group_base_dn, scope: scope, filter: filter) || []
    end

    render layout: false
  end

  def user_test_search
    set_item

    if ldap_setting.ldap_url.blank?
      @item.errors.add :base, t("ldap.errors.connection_setting_not_found")
      render layout: false
      return
    end

    if @item.user_scope.present?
      scope = Net::LDAP.const_get("SearchScope_#{@item.user_scope.classify}")
    else
      scope = Net::LDAP::SearchScope_WholeSubtree
    end

    config = ldap_setting.ldap_config
    config[:auth] = {
      method: :simple,
      username: @item.admin_dn,
      password: SS::Crypto.decrypt(@item.admin_password)
    }

    Net::LDAP.open(config) do |ldap|
      filter = Net::LDAP::Filter.construct(@item.user_filter)
      @result = ldap.search(base: @item.user_base_dn, scope: scope, filter: filter) || []
    end

    render layout: false
  end
end
