class Ldap::ServerController < ApplicationController
  include Cms::BaseFilter

  navi_view "ldap/main/navi"
  before_action :set_exclude_groups

  private

  def set_crumbs
    @crumbs << [t("ldap.server"), action: :index]
  end

  def set_exclude_groups
    @exclude_groups = SS.config.ldap.exclude_groups || []
  end

  def connect
    Ldap::Connection.connect(
      base_dn: @cur_site.root_group.ldap_dn,
      username: @cur_user.ldap_dn,
      password: session[:user]["password"]
    )
  end

  public

  def index
    if @cur_site.root_groups.length > 1
      @errors = [ t("ldap.errors.has_multiple_root_groups", site: @cur_site.name) ]
      render
      return
    end

    connection = connect
    if connection.blank?
      @errors = [ t("ldap.errors.connection_setting_not_found") ]
      render
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
  rescue Net::LDAP::Error => e
    @errors = [ e.to_s ]
    render
  rescue Errno::ECONNREFUSED => e
    @errors = [ t("ldap.errors.connection_refused") ]
    render
  end

  def group
    dn = params[:dn]
    raise "404" if dn.blank?

    connection = connect
    @entity = Ldap::Group.find(connection, dn)

    raise "404" if @entity.blank?
    render template: "ldap/server/entity"
  end

  def user
    dn = params[:dn]
    raise "404" if dn.blank?

    connection = connect
    @entity = Ldap::User.find(connection, dn)

    raise "404" if @entity.blank?
    render template: "ldap/server/entity"
  end
end
