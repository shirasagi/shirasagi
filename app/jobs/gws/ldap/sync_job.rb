require 'net/ldap/dn'

class Gws::Ldap::SyncJob < Gws::ApplicationJob
  include Job::SS::Binding::Task

  LDAP_GROUP_ATTRIBUTES = %i[dn cn member memberof].freeze
  LDAP_USER_ATTRIBUTES = %i[
    dn cn name displayName sn sAMAccountName userPrincipalName mail accountExpires isDeleted memberOf].freeze
  INITIAL_SEQUENCE = 0x8FFF_FFFF + 1

  self.task_class = Gws::Ldap::SyncTask

  def perform(*args)
    options = args.extract_options!
    @dry_run = options[:dry_run]
    if @dry_run
      @seq = INITIAL_SEQUENCE

      ::FileUtils.mkdir_p(task.base_dir) unless ::Dir.exist?(task.base_dir)
      path = "#{task.base_dir}/dry_run.zip"
      @zip = SS::Zip::Writer.create(path, comment: "created at #{Time.zone.now.iso8601}")
    end

    @imported_group_ldap_dns = Set.new
    @imported_user_ldap_dns = Set.new

    ldap_open do |ldap|
      import_all_groups(ldap)
      import_all_users(ldap)
    end

    deactivate_all_groups
    deactivate_all_users
  ensure
    @zip.close if @zip
  end

  private

  def ldap_setting
    @ldap_setting ||= begin
      if site.ldap_use_state_system?
        Sys::Auth::Setting.instance
      else
        site
      end
    end
  end

  def group_base_dn
    @group_base_dn ||= Net::LDAP::DN.new(task.group_base_dn)
  end

  def group_scope
    @group_scope ||= begin
      if task.group_scope.present?
        scope = Net::LDAP.const_get("SearchScope_#{task.group_scope.classify}")
      else
        scope = Net::LDAP::SearchScope_WholeSubtree
      end
      scope
    end
  end

  def user_base_dn
    @user_base_dn ||= Net::LDAP::DN.new(task.user_base_dn)
  end

  def ldap_open
    config = ldap_setting.ldap_config
    config[:auth] = {
      method: :simple,
      username: task.admin_dn,
      password: SS::Crypto.decrypt(task.admin_password)
    }

    Net::LDAP.open(config) do |ldap|
      Rails.logger.tagged(ldap_setting.ldap_url) do
        yield ldap
      end
    end
  end

  def all_groups_in_site
    @all_groups_in_site ||= Gws::Group.site(site).to_a
  end

  def ldap_dn_group_map_in_site
    @ldap_dn_group_map_in_site ||= all_groups_in_site.select { |group| group.ldap_dn.present? }.index_by(&:ldap_dn)
  end

  def id_group_map_in_site
    @id_group_map_in_site ||= all_groups_in_site.index_by(&:id)
  end

  # 同じ DN をもつユーザーが他テナントに存在している可能性があるので、他テナントを含む全ユーザーを捜査対象とする
  def all_users
    @all_users ||= Gws::User.all.to_a
  end

  def ldap_dn_user_map
    @ldap_dn_user_map ||= all_users.select { |user| user.ldap_dn.present? }.index_by(&:ldap_dn)
  end

  def uid_user_map
    @uid_user_map ||= all_users.index_by(&:uid)
  end

  def all_users_in_site
    @all_users_in_site ||= begin
      group_ids = all_groups_in_site.pluck(:id)
      all_users.select { |user| (user.group_ids & group_ids).present? }
    end
  end

  def all_roles_in_site
    @all_roles_in_site ||= Gws::Role.all.site(site).to_a
  end

  def id_role_map_in_site
    @id_role_map_in_site ||= all_roles_in_site.index_by(&:id)
  end

  def expiration_date
    @expiration_date ||= Time.zone.now.change(hour: 0)
  end

  def import_all_groups(ldap)
    filter = Net::LDAP::Filter.construct(task.group_filter)

    Rails.logger.tagged(group_base_dn.to_s, task.group_scope || "whole_subtree", filter.to_s) do
      entries = ldap.search(base: group_base_dn, scope: group_scope, filter: filter, attributes: LDAP_GROUP_ATTRIBUTES)
      next unless entries

      task.log("found #{entries.length} groups")

      @ldap_group_entries = entries
      @ldap_dn_group_entry_map = @ldap_group_entries.index_by do |entry|
        dn = entry["dn"].first
        ::Ldap.normalize_dn(dn)
      end

      root_dn = ::Ldap.normalize_dn(task.group_root_dn)
      root_entry = @ldap_dn_group_entry_map[root_dn]
      unless root_entry
        task.log("unable to find root group: #{task.group_root_dn}")
        return
      end

      import_root_group(root_entry)
    end
  end

  def import_root_group(entry)
    dn = entry["dn"].first
    dn = ::Ldap.normalize_dn(dn)
    site.ldap_dn = dn
    if save_item(site)
      ldap_dn_group_map_in_site[dn] = site
      @imported_group_ldap_dns << dn
      task.log("imported group: #{dn}")
    end

    @pending_members = entry["member"]
    while @pending_members.present?
      member_dn = @pending_members.shift
      member_dn = ::Ldap.normalize_dn(member_dn)
      next unless member_dn

      child_entry = @ldap_dn_group_entry_map[member_dn]
      next unless child_entry

      import_child_group(child_entry)
    end
  end

  def import_child_group(entry)
    dn = entry["dn"].first
    return unless dn

    dn = ::Ldap.normalize_dn(dn)
    Rails.logger.tagged(dn) do
      name = entry["cn"].first
      unless name
        Rails.logger.info { "unsupported entry: #{dn}" }
        return
      end

      group = ldap_dn_group_map_in_site[dn]
      group = Gws::Group.new if group.nil?

      parent_group = find_parent_group(entry)
      if parent_group
        name = "#{parent_group.name}/#{name}"
      else
        name = "#{site.name}/#{name}"
      end
      group.name = name
      group.ldap_dn = dn
      group.expiration_date = nil
      if save_item(group)
        ldap_dn_group_map_in_site[dn] ||= group
        @imported_group_ldap_dns << dn
        task.log("imported group: #{dn}")
      end

      @pending_members += entry["member"] if entry["member"].present?
    end
  end

  def find_parent_group(entry)
    parent_group_dn = entry["memberof"].first
    if parent_group_dn.present?
      parent_group_dn = ::Ldap.normalize_dn(parent_group_dn)
      parent_group = ldap_dn_group_map_in_site[parent_group_dn]
      if parent_group.nil?
        Rails.logger.warn { "unable to find parent group: #{parent_group_dn}" }
      end
      return parent_group
    end

    group_entry = @ldap_group_entries.find do |group_entry|
      group_entry["member"].any? { |member_dn| member_dn == entry["dn"].first }
    end
    if group_entry
      parent_group_dn = ::Ldap.normalize_dn(group_entry["dn"].first)
      parent_group = ldap_dn_group_map_in_site[parent_group_dn]
      if parent_group.nil?
        Rails.logger.warn { "unable to find parent group: #{parent_group_dn}" }
      end
      return parent_group
    end

    Rails.logger.info { "parent group is not defined" }
    nil
  end

  def import_all_users(ldap)
    if task.user_scope.present?
      scope = Net::LDAP.const_get("SearchScope_#{task.user_scope.classify}")
    else
      scope = Net::LDAP::SearchScope_WholeSubtree
    end
    filter = Net::LDAP::Filter.construct(task.user_filter)

    Rails.logger.tagged(user_base_dn.to_s, task.group_scope || "whole_subtree", filter.to_s) do
      entries = ldap.search(base: user_base_dn, scope: scope, filter: filter, attributes: LDAP_USER_ATTRIBUTES)
      next unless entries

      task.log("found #{entries.length} users")
      entries.each do |entry|
        import_one_user(entry)
      end
    end
  end

  def import_one_user(entry)
    dn = entry["dn"].first
    return unless dn

    dn = ::Ldap.normalize_dn(dn)
    Rails.logger.tagged(dn) do
      user = ldap_dn_user_map[dn]
      if user.nil?
        user = Gws::User.new
        user.type = Gws::User::TYPE_LDAP
        user.ldap_dn = dn
        user.organization = site
      end

      user.name = get_user_name(entry)
      user.uid = get_user_uid(entry)
      user.email = get_user_email(entry)
      if first_ldap_value(entry, "isDeleted")
        user.account_expiration_date = expiration_date
      else
        user.account_expiration_date = get_user_account_expiration_date(entry)
      end
      if entry["memberof"].present?
        group_ids = entry["memberof"].map do |group_dn|
          group = ldap_dn_group_map_in_site[group_dn]
          group.try(:id)
        end
        group_ids.compact!
        group_ids.uniq!
      else
        group_ids = [ site.id ]
      end
      set_user_group_ids(user, group_ids)
      set_user_role_ids(user)

      if uid_user_map[user.uid].present? && uid_user_map[user.uid].id != user.id
        Rails.logger.warn { "#{user.uid}: same user is already existed" }
        return
      end

      if save_item(user)
        @imported_user_ldap_dns << dn
        task.log("imported user: #{dn}")
      end
    end
  end

  def save_item(item)
    if @dry_run
      if item.new_record?
        item.id = @seq
        @seq += 1
      end

      item_key = item.to_key
      name = "collections/#{item.collection_name}/#{item_key.join(":")}.json"
      @zip.add_file(name) do |output|
        attributes = Hash[item.attributes]
        output.write attributes.to_json
      end
      true
    else
      item.record_timestamps = false
      result = item.save
      unless result
        Rails.logger.warn { "failed to save" }
        Rails.logger.warn { item.errors.full_messages.join("\n") }
      end
      result
    end
  end

  def first_ldap_value(entry, *attr_names)
    attr_names.each do |attr_name|
      attr_value = entry[attr_name.downcase]
      if attr_value && attr_value.first
        return attr_value.first
      end
    end
    nil
  end

  def get_user_name(entry)
    first_ldap_value(entry, "displayName", "name", "sn")
  end

  def get_user_uid(entry)
    value = first_ldap_value(entry, "sAMAccountName", "userPrincipalName")
    if value && value.include?("@")
      value = value.split("@", 2).first
    end
    value
  end

  def get_user_email(entry)
    first_ldap_value(entry, "userPrincipalName", "mail")
  end

  def get_user_account_expiration_date(entry)
    ::Ldap.ad_interval_to_time(first_ldap_value(entry, "accountExpires"))
  end

  def set_user_group_ids(user, group_ids)
    if user.group_ids.blank?
      user.group_ids = group_ids
      return
    end

    other_site_group_ids = user.group_ids.reject do |group_id|
      id_group_map_in_site[group_id]
    end
    if other_site_group_ids.blank?
      user.group_ids = group_ids
      return
    end

    new_group_ids = other_site_group_ids + group_ids
    new_group_ids.sort!
    new_group_ids.uniq!
    user.group_ids = new_group_ids
  end

  def set_user_role_ids(user)
    if user.gws_role_ids.blank?
      user.gws_role_ids = task.user_role_ids
      return
    end
    return if user.gws_role_ids.any? { |role_id| id_role_map_in_site[role_id] }

    new_role_ids = user.gws_role_ids + task.user_role_ids
    new_role_ids.sort!
    new_role_ids.uniq!
    user.gws_role_ids = new_role_ids
  end

  def deactivate_all_groups
    unimported_groups = all_groups_in_site.select do |group|
      next false if group.ldap_dn.blank?

      dn = ::Ldap.normalize_dn(group.ldap_dn)
      next false if @imported_group_ldap_dns.include?(dn)

      true
    end

    return if unimported_groups.blank?

    Rails.logger.info { "found #{unimported_groups.count} groups which aren't imported" }
    unimported_groups.each do |group|
      next if group.expiration_date.present?

      group.expiration_date = expiration_date
      if save_item(group)
        Rails.logger.info { "#{group.ldap_dn}: deactivated" }
      end
    end
  end

  def deactivate_all_users
    unimported_users = all_users_in_site.select do |user|
      next false if user.ldap_dn.blank?

      dn = ::Ldap.normalize_dn(user.ldap_dn)
      next false if @imported_user_ldap_dns.include?(dn)

      true
    end

    return if unimported_users.blank?

    Rails.logger.info { "found #{unimported_users.count} users which aren't imported" }
    unimported_users.each do |user|
      next if user.account_expiration_date.present?

      user.account_expiration_date = expiration_date
      if save_item(user)
        Rails.logger.info { "#{user.ldap_dn}: deactivated" }
      end
    end
  end
end
