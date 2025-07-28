class Gws::Ldap::SettingsController < ApplicationController
  include Gws::BaseFilter
  include Gws::CrudFilter

  navi_view "gws/ldap/main/navi"

  model Gws::Group

  before_action :set_addons

  private

  def set_crumbs
    @crumbs << [t("ldap.links.ldap"), gws_ldap_main_path]
    @crumbs << [t("ldap.setting"), url_for(action: :show)]
  end

  def set_addons
    @addons = []
  end

  def set_item
    @item = @cur_site
  end

  def permit_fields
    %i[ldap_use_state ldap_url ldap_openssl_verify_mode]
  end

  public

  def show
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)
    render
  end

  def edit
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)
    render
  end

  def update
    raise "403" unless @cur_user.gws_role_permit_any?(@cur_site, :edit_gws_groups)

    @item.attributes = get_params
    @item.in_updated = params[:_updated] if @item.respond_to?(:in_updated)
    render_update @item.update
  end
end
