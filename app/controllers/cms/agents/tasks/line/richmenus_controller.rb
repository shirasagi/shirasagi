class Cms::Agents::Tasks::Line::RichmenusController < ApplicationController
  #https://github.com/line/line-bot-sdk-ruby/blob/master/lib/line/bot/client.rb
  MAX_MEMBERS_TO = 400.freeze

  def with_subscribable_members(line_richmenu_id)
    criteria = Cms::Member.site(@site).and_enabled
    criteria = criteria.where(:oauth_id.exists => true, oauth_type: "line")
    criteria = criteria.ne(subscribe_richmenu_id: line_richmenu_id)
    criteria.to_a.each_slice(MAX_MEMBERS_TO).with_index do |members_to, idx|
      yield(members_to, idx)
    end
  end

  def with_subscribed_members(line_richmenu_id)
    criteria = Cms::Member.site(@site).and_enabled
    criteria = criteria.where(:oauth_id.exists => true, oauth_type: "line")
    criteria = criteria.where(subscribe_richmenu_id: line_richmenu_id)
    criteria.to_a.each_slice(MAX_MEMBERS_TO).with_index do |members_to, idx|
      yield(members_to, idx)
    end
  end

  def ineffective_user_ids(registration)
    criteria = Cms::Member.site(@site).and_enabled
    user_ids = criteria.where(:oauth_id.exists => true, oauth_type: "line").pluck(:oauth_id)
    linked_user_ids = registration ? registration.linked_user_ids : []
    linked_user_ids - user_ids
  end

  def link_default_menu(menu, registration)
    return if menu.nil? || registration.nil?

    @task.log("link default richmenu #{menu.name}:#{registration.line_richmenu_id}")
    res = @site.line_client.set_default_rich_menu(registration.line_richmenu_id)
    raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
  end

  def link_member_menu(menu, registration)
    return if menu.nil? || registration.nil?

    line_richmenu_id = registration.line_richmenu_id
    @task.log("link members richmenu #{menu.name}:#{line_richmenu_id}")

    # set subscribed richmenu
    with_subscribable_members(line_richmenu_id) do |members_to, idx|
      user_ids = members_to.map(&:oauth_id)
      @task.log("- link members #{idx * user_ids.size}..#{(idx * user_ids.size) + user_ids.size}")
      res = @site.line_client.bulk_link_rich_menus(user_ids, line_richmenu_id)
      raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/

      # set linked line_richmenu_id
      members_to.each { |member| member.set(subscribe_richmenu_id: line_richmenu_id) }
      # set linked member's user_id
      registration.add_to_set(linked_user_ids: user_ids)
    end
  end

  def unlink_member_menu(registration)
    unlink_user_ids = ineffective_user_ids(registration)
    return if unlink_user_ids.blank?

    @task.log("unlink members richmenu")
    unlink_user_ids.to_a.each_slice(MAX_MEMBERS_TO).with_index do |user_ids, idx|
      @task.log("- unlink members #{idx * user_ids.size}..#{(idx * user_ids.size) + user_ids.size}")
      @site.line_client.bulk_unlink_rich_menus(user_ids)
    end

    # set unlinked line_richmenu_id
    registration.set(linked_user_ids: (registration.linked_user_ids - unlink_user_ids)) if registration

    # set unlinked member's user_id
    criteria = Cms::Member.unscoped.site(@site).where(:oauth_id.exists => true, oauth_type: "line")
    members = criteria.in(oauth_id: unlink_user_ids).to_a
    members.each { |member| member.unset(:subscribe_richmenu_id) }
  end

  def apply_richmenu_group(group)
    menus = group.menus.to_a
    registrations = {}
    update = false
    use_alias = false

    @task.log("start registration richmenu group #{group.name}")

    # create richmenus
    menus.each do |menu|
      use_alias = true if menu.use_richmenu_alias?

      registration = Cms::Line::Richmenu::Registration.site(@site).where(menu_id: menu.id).first
      if registration && menu.updated <= registration.updated
        registrations[menu.id] = registration
        @task.log("- already registered #{menu.name}")
        next
      else
        @task.log("- start registration #{menu.name}")
      end

      registration = Cms::Line::Richmenu::Registration.new
      registration.site = @site
      registration.menu = menu

      # create richmenu object
      @task.log("-- create #{menu.name}")
      res = @site.line_client.create_rich_menu(menu.richmenu_object)
      raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
      line_richmenu_id = (JSON.parse(res.body))['richMenuId']

      # upload richmenu image
      @task.log("-- upload #{menu.image.name}")
      file = ::File.open(menu.image.path)
      file.instance_variable_set("@_content_type", menu.image.content_type)
      def file.content_type
        instance_variable_get("@_content_type")
      end
      res = @site.line_client.create_rich_menu_image(line_richmenu_id, file)
      raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/

      registration.line_richmenu_id = line_richmenu_id
      registration.line_richmenu_alias_id = menu.richmenu_alias
      registration.save!
      registrations[menu.id] = registration
      update = true
    end

    # apply richmenu alias
    if use_alias && update
      @task.log("start registration richmenu alias")

      # get already registered alias
      res = @site.line_client.get_rich_menus_alias_list
      raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
      registered_aliases = JSON.parse(res.body)["aliases"].map { |h| [h["richMenuAliasId"], h["richMenuId"]] }.to_h
      created_aliases = {}

      # create alias
      menus.each do |menu|
        menu.richmenu_areas.select{ |area| area.use_richmenu_alias? }.each do |area|
          registration = registrations[area.menu.id]
          line_richmenu_id = registration.line_richmenu_id
          line_richmenu_alias_id = registration.line_richmenu_alias_id

          next if created_aliases[line_richmenu_alias_id]

          if registered_aliases[line_richmenu_alias_id]
            @task.log("- update richmenu alias #{area.menu.name}:#{line_richmenu_id}")
            res = @site.line_client.update_rich_menus_alias(line_richmenu_id, line_richmenu_alias_id)
          else
            @task.log("- create richmenu alias #{area.menu.name}:#{line_richmenu_id}")
            res = @site.line_client.set_rich_menus_alias(line_richmenu_id, line_richmenu_alias_id)
            created_aliases[line_richmenu_alias_id] = line_richmenu_id
          end
          raise "#{res.code} #{res.body}" if res.code !~ /^2\d\d$/
        end
      end
    end

    # link all users menu
    menu = menus.select { |menu| menu.target == "default" }.first
    registration = menu ? registrations[menu.id] : nil
    link_default_menu(menu, registration)

    # link members menu
    menu = menus.select { |menu| menu.target == "member" }.first
    registration = menu ? registrations[menu.id] : nil
    link_member_menu(menu, registration)

    # unlink ineffective members menu
    unlink_member_menu(registration)

    registrations
  end

  def delete_unused_richmenu(registrations)
    items = Cms::Line::Richmenu::Registration.site(@site).nin(id: registrations.values.map(&:id)).to_a
    return if items.blank?

    @task.log("delete unused richmenu (also unlink menu)")
    items.each do |registration|
      @task.log("- delete richmenu object #{registration.line_richmenu_id}")
      line_richmenu_id = registration.line_richmenu_id
      @site.line_client.delete_rich_menu(line_richmenu_id)

      # unset subscribed richmenu
      with_subscribed_members(line_richmenu_id) do |members_to, idx|
        members_to.each { |member| member.unset(:subscribe_richmenu_id) }
      end
      registration.destroy
    end
  end

  def apply
    item = Cms::Line::Richmenu::Group.site(@site).active_group
    registrations = {}
    registrations = apply_richmenu_group(item) if item
    delete_unused_richmenu(registrations)
    head :ok
  end
end
