class Ldap::ServerController < ApplicationController
  include Cms::BaseFilter

  navi_view "ldap/main/navi"
  before_action :set_exclude_groups

  private
    def set_crumbs
      @crumbs << [:"ldap.server", action: :index]
    end

    def set_exclude_groups
      @exclude_groups = SS.config.ldap.exclude_groups || []
    end

  public
    def index
      connection = Ldap::Connection.connect(@cur_site.root_group, @cur_user.ldap_dn, session[:password])
      if connection.blank?
        @errors = [ t("ldap.errors.connection_setting_not_found") ]
        render status: :bad_request
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
      render status: :bad_request
    end

    def group
      dn = params[:dn]
      raise "404" if dn.blank?

      connection = Ldap::Connection.connect(@cur_site.root_group, @cur_user.ldap_dn, session[:password])
      @entity = Ldap::Group.find(connection, dn)

      raise "404" if @entity.blank?
      render file: "ldap/server/entity"
    end

    def user
      dn = params[:dn]
      raise "404" if dn.blank?

      connection = Ldap::Connection.connect(@cur_site.root_group, @cur_user.ldap_dn, session[:password])
      @entity = Ldap::User.find(connection, dn)

      raise "404" if @entity.blank?
      render file: "ldap/server/entity"
    end
end
