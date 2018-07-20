## -------------------------------------
puts "# discussion/forum"

def create_discussion_forum(data)
  create_item(Gws::Discussion::Forum, data)
end

@ds_forums = [
  create_discussion_forum(
    name: 'サイト改善プロジェクト', order: 0, user_ids: [u('admin').id], member_ids: @users.map(&:id)
  ),
  create_discussion_forum(
    name: "#{@site_name}プロジェクト", order: 10, user_ids: [u('admin').id], member_custom_group_ids: [@cgroups.first.id]
  ),
  create_discussion_forum(
    name: '地域振興イベント', order: 30, user_ids: [u('sys').id],
    member_ids: [u('sys').id], member_group_ids: [g('企画政策部'), g('政策課'), g('広報課')].map(&:id)
  ),
]

def create_discussion_topic(data)
  # puts data[:name]
  cond = { site_id: @site._id, forum_id: data[:forum_id], parent_id: data[:parent_id], text: data[:text] }
  item = Gws::Discussion::Topic.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(
    cur_site: @site, cur_user: u('admin'),
    contributor_name: u('admin').long_name,
    contributor_id: u('admin').id,
    contributor_model: "Gws::User"
  )
  puts item.errors.full_messages unless item.save
  item
end

@ds_topics = [
  create_discussion_topic(
    name: 'メインスレッド', text: 'サイト改善プロジェクトのメインスレッドです。', order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id, user_ids: [u('admin').id]
  ),
  create_discussion_topic(
    name: '問い合わせフォームの改善', text: '問い合わせフォームの改善について意見をお願いします。', order: 10,
    forum_id: @ds_forums[0].id, parent_id: @ds_forums[0].id, user_ids: [u('admin').id]
  ),
  create_discussion_topic(
    name: 'メインスレッド', text: "#{@site_name}プロジェクトのメインスレッドです。", order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[1].id, parent_id: @ds_forums[1].id, user_ids: [u('admin').id]
  ),
  create_discussion_topic(
    name: 'メインスレッド', text: '地域振興イベントのメインスレッドです。', order: 0, main_topic: 'enabled',
    forum_id: @ds_forums[2].id, parent_id: @ds_forums[2].id, user_ids: [u('sys').id]
  ),
  create_discussion_topic(
    name: '7月8日開催のイベント内容について', text: '7月8日に開催されるイベント内容について投稿してください。', order: 10, main_topic: 'enabled',
    forum_id: @ds_forums[2].id, parent_id: @ds_forums[2].id, user_ids: [u('sys').id]
  ),
]

def create_discussion_post(data)
  # puts data[:name]
  cond = { site_id: @site._id, forum_id: data[:forum_id], parent_id: data[:parent_id], text: data[:text] }
  item = Gws::Discussion::Post.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(
    cur_site: @site, cur_user: u('admin'),
    contributor_name: u('admin').long_name,
    contributor_id: u('admin').id,
    contributor_model: "Gws::User"
  )
  puts item.errors.full_messages unless item.save
  item
end

create_discussion_post(
  name: 'メインスレッド', text: "#{@site_name}市のサイト改善を図りたいと思いますので、皆様のご意見をお願いします。",
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user4'), name: 'メインスレッド', text: '全体的なデザインの見直しを行いたいです。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user5'), name: 'メインスレッド', text: '観光コンンテンツは別途観光サイトを設けたいと思います。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[0].id, parent_id: @ds_topics[0].id, user_ids: [u('admin').id]
)
create_discussion_post(
  cur_user: u('user3'), name: '問い合わせフォームの改善', text: '投稿時に問い合わせ先の課を選択でき、投稿通知が対象課に届くと良いと思います。',
  forum_id: @ds_forums[0].id, topic_id: @ds_topics[1].id, parent_id: @ds_topics[1].id, user_ids: [u('admin').id]
)
create_discussion_post(
  name: 'メインスレッド', text: "#{@site_name}の改善要望について議論を交わしたいと思います。",
  forum_id: @ds_forums[1].id, topic_id: @ds_topics[2].id, parent_id: @ds_topics[2].id, user_ids: [u('admin').id]
)
create_discussion_post(
  name: 'メインスレッド', text: '定期開催されている地域振興イベントについてのご意見・ご要望を投稿してください。',
  forum_id: @ds_forums[2].id, topic_id: @ds_topics[3].id, parent_id: @ds_topics[3].id, user_ids: [u('sys').id]
)
create_discussion_post(
  cur_user: u('user5'), name: 'メインスレッド', text: 'クロサギ株式会社様にも協力を依頼しています。',
  forum_id: @ds_forums[2].id, topic_id: @ds_topics[3].id, parent_id: @ds_topics[3].id, user_ids: [u('sys').id]
)
create_discussion_post(
  cur_user: u('user1'), name: '7月8日開催のイベント内容について', text: '来週月曜日にコーディネーターの方からまとまった資料をいただける予定です。',
  forum_id: @ds_forums[2].id, topic_id: @ds_topics[4].id, parent_id: @ds_topics[4].id, user_ids: [u('sys').id]
)
