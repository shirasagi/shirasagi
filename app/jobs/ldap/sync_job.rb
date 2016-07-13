class Ldap::SyncJob < Cms::ApplicationJob
  include Job::SS::TaskFilter

  self.task_class = Ldap::SyncTask
  self.task_name = "ldap::sync"

  attr_reader :results

  def perform(group_id, item_id)
    @group = Cms::Group.find(group_id).root
    @item = Ldap::Import.find(item_id)
    @results = { group: {}, user: {} }
    @results[:group][:successed] = 0
    @results[:group][:failed] = 0
    @results[:group][:deleted] = 0
    @results[:group][:errors] = []
    @results[:group][:warnings] = []
    @results[:user][:successed] = 0
    @results[:user][:failed] = 0
    @results[:user][:deleted] = 0
    @results[:user][:errors] = []
    @results[:user][:warnings] = []

    old_ldap_group_ids = Cms::Group.where(name: /^#{Regexp.escape(@group.name)}\//).exists(ldap_dn: true).pluck(:id)

    sync_ldap_groups(@group, @item.ldap.root_groups)

    # delete old entities
    individual_criteria = [ Cms::Group.where(name: /^#{Regexp.escape(@group.name)}\//),
                            Cms::User.in(group_ids: old_ldap_group_ids) ]
    num_deletes = individual_criteria.map do |c|
      # append common criteria
      c = c.exists(ldap_dn: true).ne(ldap_import_id: @item.id)
      # and delete
      c.delete
    end
    @results[:group][:deleted], @results[:user][:deleted] = num_deletes

    rearrange_group_order
    task.results = @results

    self
  end

  private
    def sync_ldap_groups(ss_group, ldap_groups)
      ldap_groups.each do |ldap_group|
        sync_ldap_group(ss_group, ldap_group)
      end
    end

    def sync_ldap_group(ss_parent_group, ldap_group)
      ss_group = Cms::Group.where(ldap_dn: ldap_group.dn).first
      ss_group ||= Cms::Group.new

      ss_group.name = mk_group_name(ss_parent_group, ldap_group)
      ss_group.contact_tel = ldap_group.contact_tel if ldap_group.contact_tel.present?
      ss_group.contact_email = ldap_group.contact_email if ldap_group.contact_email.present?
      ss_group.ldap_dn = ldap_group.dn
      ss_group.ldap_import_id = @item.id
      if ss_group.save
        @results[:group][:successed] += 1

        sync_ldap_groups(ss_group, @item.ldap.child_groups(ldap_group.dn))
        sync_ldap_users(ss_group, @item.ldap.child_users(ldap_group.dn))
      else
        @results[:group][:failed] += 1
        @results[:group][:errors] << ss_group.errors.full_messages.map do |message|
          "#{ss_group.name}: #{message}"
        end
      end
    end

    def mk_group_name(ss_parent_group, ldap_group)
      if ss_parent_group.present?
        [ ss_parent_group.name, ldap_group.name ].join("/")
      else
        ldap_group.name
      end
    end

    def sync_ldap_users(ss_group, ldap_users)
      ldap_users.each do |ldap_user|
        ss_user = Cms::User.where(ldap_dn: ldap_user.dn).first
        new_user = ss_user.blank?
        ss_user ||= Cms::User.new

        same_group = new_user ? true : same_group?(ss_user.group_ids, [ ss_group.id ])

        ss_user.name = ldap_user.name
        ss_user.uid = ldap_user.uid
        ss_user.email = ldap_user.email if ldap_user.email.present?
        ss_user.group_ids = [ ss_group.id ]
        ss_user.login_roles = [SS::User::LOGIN_ROLE_LDAP]
        ss_user.ldap_dn = ldap_user.dn
        ss_user.ldap_import_id = @item.id
        if ss_user.save
          @results[:user][:successed] += 1
          unless same_group
            msg = I18n.t("ldap.messages.group_moved", user_name: ss_user.long_name, group_name: ss_group.name)
            @results[:user][:warnings] << msg
          end
        else
          @results[:user][:failed] += 1
          @results[:user][:errors] << ss_user.errors.full_messages.map do |message|
            "#{ss_user.long_name}: #{message}"
          end
        end
      end
    end

    def same_group?(old_group_ids, new_group_ids)
      old_group_ids.to_a == new_group_ids.to_a
    end

    def rearrange_group_order
      ordered_groups = Cms::Group.each.sort(&method(:order_by_name)).map.with_index(1) do |g, i|
        g.order = i * 10
        g
      end
      ordered_groups.each(&:save!)
    end

    def order_by_name(lhs, rhs)
      lhs.name <=> rhs.name
    end
end
