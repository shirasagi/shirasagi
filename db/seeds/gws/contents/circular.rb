puts "# circular/category"

def create_circular_category(data)
  create_item(Gws::Circular::Category, data)
end

@cr_cate = [
  create_circular_category(name: "必読", color: "#FF0000", order: 10),
  create_circular_category(name: "案内", color: "#09FF00", order: 20)
]

## -------------------------------------
puts "# circular/post"

def create_circular_post(data)
  create_item(Gws::Circular::Post, data)
end

@cr_posts = [
  create_circular_post(
    name: "年末年始休暇について", text: "年末年始の休暇は12月29日から1月3日までとなります。\nお間違えないようお願いします。",
    see_type: "normal", state: 'public', due_date: @now.beginning_of_day + 7.days,
    member_ids: %w(sys admin user1 user2 user3 user4 user5).map { |u| u(u).id },
    seen: { u('user2').id.to_s => @now, u('user5').id.to_s => @now },
    category_ids: [@cr_cate[0].id]
  ),
  create_circular_post(
    name: "システム説明会のお知らせ", text: "システム説明会を開催します。\n万障お繰り合わせの上ご参加願います。",
    see_type: "normal", state: 'public', due_date: @now.beginning_of_day + 7.days,
    member_ids: %w(sys admin user1 user3 user5).map { |u| u(u).id },
    seen: { u('admin').id.to_s => @now, u('user3').id.to_s => @now },
    category_ids: [@cr_cate[1].id]
  ),
  create_circular_post(
    name: "健康診断のお知らせ", text: "職員各位\n下記の通り健康診断を行いますので、各自受診をお願いします。\n
  　　　　　　　　　　　　　　　　　　　　1.日時: ○月○日 (月) ~ ○月○日 (金)\n 2.場所: #{@site_name}医院　",
    see_type: "normal", state: 'public', due_date: @now.beginning_of_day + 7.days,
    member_ids: %w(sys admin user1 user3 user5).map { |u| u(u).id },
    seen: { u('admin').id.to_s => @now, u('user3').id.to_s => @now },
    category_ids: [@cr_cate[1].id]
  ),
]

def create_circular_comment(data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id, name: data[:name] }
  item = Gws::Circular::Comment.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  puts item.errors.full_messages unless item.save
  item
end

create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user5'), name: "Re: 年末年始休暇について", text: "内容確認しました。"
)
create_circular_comment(
  post_id: @cr_posts[0].id, cur_user: u('user2'), name: "Re: 年末年始休暇について", text: "承知しました。"
)
create_circular_comment(
  post_id: @cr_posts[1].id, cur_user: u('user3'), name: "Re: システム説明会のお知らせ",
  text: "予定があり参加できそうにありません。"
)
create_circular_comment(
  post_id: @cr_posts[1].id, cur_user: u('admin'), name: "Re: システム説明会のお知らせ", text: "参加します。"
)
