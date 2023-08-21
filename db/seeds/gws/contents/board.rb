puts "# board/category"

def create_board_category(data)
  create_item(Gws::Board::Category, data)
end

@bd_cate = [
  create_board_category(name: "告知", color: "#002288", order: 10, readable_setting_range: "public"),
  create_board_category(name: "質問", color: "#EE00DD", order: 20, readable_setting_range: "public"),
  create_board_category(name: "募集", color: "#CCCCCC", order: 30, readable_setting_range: "public")
]

## -------------------------------------
puts "# board/post"

def create_board_topic(data)
  create_item(Gws::Board::Topic, data)
end

@bd_topics = [
  create_board_topic(
    name: "業務説明会を開催します。", text: "#{@site_name}についても業務説明会を開催します。", mode: "thread",
    category_ids: [@bd_cate[0].id], member_group_ids: @groups.pluck(:id).sort
  ),
  create_board_topic(
    name: "会議室の増設について",
    text: "会議室の利用率が高いので増設を考えています。\n特に希望される内容などあればお願いします。", mode: "tree",
    category_ids: [@bd_cate[1].id], member_group_ids: @groups.pluck(:id).sort
  )
]

def create_board_post(data)
  create_item(Gws::Board::Post, data)
end

create_board_post(
  cur_user: u('user1'), name: "Re: 業務説明会を開催します。", text: "参加は自由ですか。",
  topic_id: @bd_topics[0].id, parent_id: @bd_topics[0].id
)
res = create_board_post(
  cur_user: u('user1'), name: "Re: 会議室の増設について", text: "政策課フロアに増設いただけると助かります。",
  topic_id: @bd_topics[1].id, parent_id: @bd_topics[1].id
)
res = create_board_post(
  cur_user: u('admin'), name: "Re: Re: 会議室の増設について", text: "検討します。",
  topic_id: @bd_topics[1].id, parent_id: res.id
)
