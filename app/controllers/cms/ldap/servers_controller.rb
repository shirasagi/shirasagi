class Cms::Ldap::ServersController < ApplicationController
  include Cms::BaseFilter

  navi_view "cms/ldap/main/navi"
  menu_view nil
  before_action :set_exclude_groups

  private

  def set_crumbs
    @crumbs << [t("ldap.server"), action: :main]
  end

  def set_exclude_groups
    @exclude_groups = @cur_site.ldap_exclude_groups || []
  end

  def connect
    Ldap::Connection.connect(
      url: @cur_site.ldap_url,
      base_dn: @cur_site.ldap_base_dn,
      auth_method: @cur_site.ldap_auth_method,
      username: @cur_site.ldap_user_dn,
      password: @cur_site.ldap_user_password ? SS::Crypto.decrypt(@cur_site.ldap_user_password) : nil
    )
  end

  public

  def show
    connection = connect
    if connection.blank?
      @errors = [ t("ldap.errors.connection_setting_not_found") ]
      render "show"
      return
    end

    dn = params[:dn]
    if dn.blank?
      @parent_group = nil
      @groups = connection.groups
      @users = connection.users
    else
      @parent_group = Ldap::Group.find(connection, dn)
      @groups = @parent_group.try(:groups) || []
      @users = @parent_group.try(:users) || []
    end

    render "show"
  rescue Net::LDAP::Error => e
    @errors = [ e.to_s ]
    render "show"
  rescue Errno::ECONNREFUSED => e
    @errors = [ t("ldap.errors.connection_refused") ]
    render "show"
  end
  alias main show

  def group
    dn = params[:dn]
    raise "404" if dn.blank?

    connection = connect
    @entity = ::Ldap::Group.find(connection, dn)

    raise "404" if @entity.blank?
    render "entity"
  end

  def user
    dn = params[:dn]
    raise "404" if dn.blank?

    connection = connect
    @entity = ::Ldap::User.find(connection, dn)

    raise "404" if @entity.blank?
    render "entity"
  end
end
