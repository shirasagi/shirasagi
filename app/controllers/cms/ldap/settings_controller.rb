class Cms::Ldap::SettingsController < ApplicationController
  include Cms::BaseFilter
  include Cms::CrudFilter

  navi_view "cms/ldap/main/navi"

  model Cms::Site

  before_action :set_addons

  private

  def set_crumbs
    @crumbs << [t("ldap.setting"), url_for(action: :show)]
  end

  def set_addons
    @addons = []
  end

  def set_item
    @item = @cur_site
  end

  def permit_fields
    %i[
      ldap_use_state ldap_url ldap_openssl_verify_mode ldap_base_dn ldap_auth_method
      ldap_user_dn in_ldap_user_password ldap_exclude_groups
    ]
  end

  public

  def show
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def edit
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)
    render
  end

  def update
    raise "403" unless Cms::Tool.allowed?(:read, @cur_user, site: @cur_site)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end
end
