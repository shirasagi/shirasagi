puts "# bookmark"

def create_bookmark(data)
  puts data[:name]
  cond = {site_id: @site._id, user_id: data[:cur_user].id, name: data[:name]}
  item = Gws::Bookmark.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

create_bookmark(
  cur_user: u('sys'), name: @faq_topics[0].name, url: "/.g#{@site.id}/faq/topics/#{@faq_topics[0].id}",
  bookmark_model: 'faq'
)
create_bookmark(
  cur_user: u('sys'), name: '企画政策課座席表', url: "/.g#{@site.id}/share/folder-#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}",
  bookmark_model: 'share'
)
create_bookmark(
  cur_user: u('sys'), name: 'SHIRASAGI公式サイト', url: 'http://www.ss-proj.org/',
  bookmark_model: 'other'
)
create_bookmark(
  cur_user: u('sys'), name: 'お気に入り', url: "/.g#{@site.id}gws/bookmarks#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}",
  bookmark_model: 'bookmark'
)

create_bookmark(
  cur_user: u('admin'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('admin'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[1].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('admin'), name: @cr_posts[1].name, url: "/.g#{@site.id}/circular/admins/#{@cr_posts[1].id}",
  bookmark_model: 'circular'
)

create_bookmark(
  cur_user: u('user1'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user1'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[1].id}/topics",
  bookmark_model: 'discussion'
)

create_bookmark(
  cur_user: u('user2'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user2'), name: @sh_files[0].name,
  url: "/.g#{@site.id}/share/folder-#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}",
  bookmark_model: 'share'
)

create_bookmark(
  cur_user: u('user3'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user3'), name: @mon_topics[0].name, url: "/.g1/monitor/topics/#{@mon_topics[0].id}",
  bookmark_model: 'monitor'
)

create_bookmark(
  cur_user: u('user4'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user4'), name: @bd_topics[0].name, url: "/.g#{@site.id}/board/topics/#{@bd_topics[0].id}",
  bookmark_model: 'board'
)

create_bookmark(
  cur_user: u('user5'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/forums/#{@ds_forums[0].id}/topics",
  bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user5'), name: @bd_topics[1].name, url: "/.g#{@site.id}/board/topics/#{@bd_topics[1].id}",
  bookmark_model: 'board'
)
