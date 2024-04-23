require 'net/ldap/dn'

class Gws::Ldap::SyncJob < Gws::ApplicationJob
  include Job::SS::Binding::Task

  LDAP_GROUP_ATTRIBUTES = %i[dn cn member memberof].freeze
  LDAP_USER_ATTRIBUTES = %i[dn cn name employeeNumber mail memberof preferredlanguage].freeze
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

    ldap_open do |ldap|
      import_all_groups(ldap)
      import_all_users(ldap)
    end
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

  def import_all_groups(ldap)
    if task.group_scope.present?
      scope = Net::LDAP.const_get("SearchScope_#{task.group_scope.classify}")
    else
      scope = Net::LDAP::SearchScope_WholeSubtree
    end
    filter = Net::LDAP::Filter.construct(task.group_filter)

    Rails.logger.tagged(group_base_dn.to_s, task.group_scope || "whole_subtree", filter.to_s) do
      entries = ldap.search(base: group_base_dn, scope: scope, filter: filter, attributes: LDAP_GROUP_ATTRIBUTES)
      next unless entries

      task.log("found #{entries.length} groups")

      @ldap_group_entries = entries
      @ldap_dn_group_entry_map = @ldap_group_entries.index_by do |entry|
        dn = entry["dn"].first
        normalize_dn(dn)
      end

      root_dn = normalize_dn(task.group_root_dn)
      root_entry = @ldap_dn_group_entry_map[root_dn]
      unless root_entry
        task.log("unable to find root group: #{task.group_root_dn}")
        return
      end

      import_root_group(root_entry)
    end
  end

  def normalize_dn(dn)
    Net::LDAP::DN.new(dn).to_s
  end

  def import_root_group(entry)
    dn = entry["dn"].first
    dn = normalize_dn(dn)
    site.ldap_dn = dn
    save_item!(site)
    ldap_dn_group_map[dn] = site
    task.log("imported group: #{dn}")

    @pending_members = entry["member"]
    while @pending_members.present?
      member_dn = @pending_members.shift
      member_dn = normalize_dn(member_dn)
      next unless member_dn

      child_entry = @ldap_dn_group_entry_map[member_dn]
      next unless child_entry

      import_child_group(child_entry)
    end
  end

  def import_child_group(entry)
    dn = entry["dn"].first
    return unless dn
    dn = normalize_dn(dn)

    name = entry["cn"].first
    unless name
      Rails.logger.info { "unsupported entry: #{dn}" }
      return
    end

    group = ldap_dn_group_map[dn]
    group = Gws::Group.new if group.nil?

    parent_group_dn = entry["memberof"].first
    if parent_group_dn.present?
      parent_group_dn = normalize_dn(parent_group_dn)
      parent_group = ldap_dn_group_map[parent_group_dn]
      if parent_group.nil?
        Rails.logger.warn { "parent group is not found: #{parent_group_dn}" }
      end
    end
    if parent_group
      name = "#{parent_group.name}/#{name}"
    else
      name = "#{site.name}/#{name}"
    end
    group.name = name
    group.ldap_dn = dn
    save_item!(group)
    ldap_dn_group_map[dn] ||= group
    task.log("imported group: #{dn}")

    @pending_members += entry["member"] if entry["member"].present?
  end

  def all_groups
    @all_groups ||= begin
      Gws::Group.site(site).to_a
    end
  end

  def ldap_dn_group_map
    @ldap_dn_group_map ||= all_groups.select { |group| group.ldap_dn.present? }.index_by(&:ldap_dn)
  end

  def all_users
    @all_users ||= begin
      Gws::User.site(site).to_a
    end
  end

  def ldap_dn_user_map
    @ldap_dn_user_map ||= all_users.select { |user| user.ldap_dn.present? }.index_by(&:ldap_dn)
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
    # unless supported_user_object_class?(entry)
    #   Rails.logger.info { "unsupported objectClass: #{entry["objectclass"].join(",")}" }
    #   return
    # end

    dn = entry["dn"].first
    return unless dn

    dn = normalize_dn(dn)
    user = ldap_dn_user_map[dn]
    if user.nil?
      user = Gws::User.new
      user.type = Gws::User::TYPE_LDAP
      user.ldap_dn = dn
      user.organization = site
      user.gws_role_ids = task.user_role_ids
    end

    # cn: If the object corresponds to a person, it is typically the person's full name.
    # see: https://www.rfc-editor.org/rfc/rfc4519.html#section-2.3
    user.name = entry["name"].first
    # https://www.rfc-editor.org/rfc/rfc4519.html#section-2.39
    user.uid = entry["cn"].first
    user.organization_uid = entry["employeeNumber"].first
    user.email = entry["mail"].first
    if entry["memberof"].present?
      group_ids = entry["memberof"].map do |group_dn|
        group = ldap_dn_group_map[group_dn]
        group.try(:id)
      end
      group_ids.compact!
      group_ids.uniq!
    else
      group_ids = [ site.id ]
    end
    user.group_ids = group_ids

    if entry["preferredlanguage"].present?
      lang = entry["preferredlanguage"].first
      if lang.present? && I18n.available_locales.include?(lang.to_sym)
        user.lang = lang
      end
    end

    save_item!(user)
    task.log("imported user: #{dn}")
  end

  def save_item!(item)
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
    else
      item.save!
    end
  end
end
