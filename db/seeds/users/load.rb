Dir.chdir @root = File.dirname(__FILE__)
@site = SS::Site.find_by host: ENV["site"]

## -------------------------------------
puts "# groups"

def save_group(data)
  puts data[:name]
  cond = { name: data[:name] }

  item = SS::Group.find_or_create_by cond
  item.update data
  item
end

g1_00 = save_group name: "シラサギ市"
g1_10 = save_group name: "シラサギ市/企画政策部"
g1_11 = save_group name: "シラサギ市/企画政策部/政策課"
g1_12 = save_group name: "シラサギ市/企画政策部/広報課"
g1_20 = save_group name: "シラサギ市/危機管理部"
g1_21 = save_group name: "シラサギ市/危機管理部/管理課"
g1_22 = save_group name: "シラサギ市/危機管理部/防災課"

@site.add_to_set group_ids: g1_00.id

## -------------------------------------
puts "# roles"

def save_cms_role(data)
  puts data[:name]
  cond = { name: data[:name], site_id: @site.id }

  item = Cms::Role.find_or_create_by cond
  item.update data.merge site_id: @site.id
  item
end

role1 = save_cms_role name: "サイト管理者", permission_level: 3,
  permissions: Cms::Role.permission_names

role2 = save_cms_role name: "記事編集権限", permission_level: 1,
  permissions: %w(
    read_private_article_pages edit_private_article_pages
    delete_private_article_pages read_other_article_pages
    edit_other_article_pages delete_other_article_pages

    read_private_faq_pages edit_private_faq_pages
    delete_private_faq_pages read_other_faq_pages
    edit_other_faq_pages delete_other_faq_pages

    read_private_event_pages edit_private_event_pages
    delete_private_event_pages read_other_event_pages
    edit_other_event_pages delete_other_event_pages

    approve_other_article_pages approve_private_article_pages
    approve_other_cms_pages approve_private_cms_pages
    approve_other_faq_pages approve_private_faq_pages
    approve_other_event_pages approve_private_event_pages

    read_private_cms_nodes read_other_cms_nodes
  )

@sys_user = SS::User.where(email: "sys@example.jp").first
if @sys_user
  @sys_user.add_to_set group_ids: g1_00.id
  @sys_user.add_to_set cms_role_ids: role1.id
end

## -------------------------------------
puts "# users"

def save_user(data)
  puts data[:name]
  data[:in_password] = data[:password]
  data.delete(:password)

  group_ids = data[:group_ids]
  data.delete(:group_ids)
  cms_role_ids = data[:cms_role_ids]
  data.delete(:cms_role_ids)

  cond = { email: data[:email] }

  item = SS::User.find_or_create_by cond
  item.update data

  item.add_to_set group_ids: group_ids
  item.add_to_set cms_role_ids: cms_role_ids
  item.update

  item
end

@admin = save_user name: "サイト管理者", email: "admin@example.jp", password: "pass",
  group_ids: [g1_11.id], cms_role_ids: [role1.id]
@user1 = save_user name: "一般ユーザー1", email: "user1@example.jp", password: "pass",
  group_ids: [g1_11.id, g1_21.id], cms_role_ids: [role2.id]
@user2 = save_user name: "一般ユーザー2", email: "user2@example.jp", password: "pass",
  group_ids: [g1_22.id], cms_role_ids: [role2.id]

## -------------------------------------
puts "# nodes"

def save_node(data)
  puts data[:name]
  klass = data[:route].sub("/", "/node/").singularize.camelize.constantize

  cond = { site_id: @site._id, filename: data[:filename] }
  item = klass.unscoped.find_or_create_by cond

  item.update data

  item.add_to_set group_ids: @admin.group_ids
  item.add_to_set group_ids: @user1.group_ids
  item.add_to_set group_ids: @user2.group_ids
  item.update
end

save_node route: "article/page", filename: "docs", name: "記事", shortcut: "show"
