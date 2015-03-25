class Ldap::ImportJob
  include Job::Worker

  attr_accessor :exclude_groups

  public
    def call(site_id, user_id, password)
      @site = SS::Site.find(site_id)
      @user = SS::User.find(user_id)
      @group_count = 0
      @user_count = 0
      @exclude_groups ||= SS.config.ldap.exclude_groups

      connection = Ldap::Connection.connect(base_dn: @site.root_group.ldap_dn, username: @user.ldap_dn, password: password)
      if connection.blank?
        raise I18n.t("ldap.errors.connection_setting_not_found")
      end

      import_groups(nil, connection.groups)
    end

  private
    def import_groups(parent_dn, groups)
      ldap_array = convert_groups(parent_dn, groups)
      Ldap::Import.create!(
        {
          site_id: @site.id,
          group_count: @group_count,
          user_count: @user_count,
          ldap: ldap_array
        })
    end

    def convert_groups(parent_dn, groups)
      groups.map do |group|
        convert_group(parent_dn, group)
      end.flatten
    end

    def convert_group(parent_dn, group)
      return [] if @exclude_groups.try(:include?, group.name)

      entity = Ldap::Extensions::LdapEntity.convert_group(group, parent_dn: parent_dn)
      @group_count += 1
      ret = [ entity ]
      ret << convert_groups(entity[:dn], group.groups)
      ret << convert_users(entity[:dn], group.users)
      ret
    end

    def convert_users(parent_dn, users)
      @user_count += users.length
      users.map do |user|
        Ldap::Extensions::LdapEntity.convert_user(user, parent_dn: parent_dn)
      end
    end
end