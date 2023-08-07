puts "# bookmark"

def create_bookmark(data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id, folder_id: data[:folder].id, name: data[:name] }
  item = Gws::Bookmark::Item.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

folder = u('sys').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('sys'), name: @faq_topics[0].name, url: "/.g#{@site.id}/faq/-/-/topics/#{@faq_topics[0].id}",
  folder: folder, bookmark_model: 'faq'
)
create_bookmark(
  cur_user: u('sys'), name: '企画政策課座席表', url: "/.g#{@site.id}/share/folder-#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}",
  folder: folder, bookmark_model: 'share'
)
create_bookmark(
  cur_user: u('sys'), name: 'SHIRASAGI公式サイト', url: 'http://www.ss-proj.org/',
  folder: folder, bookmark_model: 'other'
)
create_bookmark(
  cur_user: u('sys'), name: 'お気に入り', url: "/.g#{@site.id}/gws/bookmarks",
  folder: folder, bookmark_model: 'bookmark'
)

folder = u('admin').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('admin'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('admin'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[1].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('admin'), name: @cr_posts[1].name, url: "/.g#{@site.id}/circular/-/admins/#{@cr_posts[1].id}",
  folder: folder, bookmark_model: 'circular'
)

foler = u('user1').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('user1'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user1'), name: @ds_forums[1].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[1].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)

folder = u('user2').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('user2'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user2'), name: @sh_files[0].name,
  url: "/.g#{@site.id}/share/folder-#{@sh_files[0].folder_id}/files/#{@sh_files[0].id}",
  folder: folder, bookmark_model: 'share'
)

folder = u('user3').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('user3'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user3'), name: @mon_topics[0].name, url: "/.g1/monitor/-/topics/#{@mon_topics[0].id}",
  folder: folder, bookmark_model: 'monitor'
)

folder = u('user4').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('user4'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user4'), name: @bd_topics[0].name, url: "/.g#{@site.id}/board/-/-/topics/#{@bd_topics[0].id}",
  folder: folder, bookmark_model: 'board'
)

folder = u('user5').bookmark_root_folder(@site)
create_bookmark(
  cur_user: u('user5'), name: @ds_forums[0].name, url: "/.g#{@site.id}/discussion/-/forums/#{@ds_forums[0].id}/topics",
  folder: folder, bookmark_model: 'discussion'
)
create_bookmark(
  cur_user: u('user5'), name: @bd_topics[1].name, url: "/.g#{@site.id}/board/-/-/topics/#{@bd_topics[1].id}",
  folder: folder, bookmark_model: 'board'
)
