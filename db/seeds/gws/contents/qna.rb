puts "# qna/category"

def create_qna_category(data)
  create_item(Gws::Qna::Category, data)
end

@qna_cate = [
  create_qna_category(name: '福利厚生', color: '#0033FF', order: 10),
  create_qna_category(name: '防災', color: '#F700FF', order: 20)
]

## -------------------------------------
puts "# qna/topic"

def create_qna_topic(data)
  create_item(Gws::Qna::Topic, data)
end

@qna_topics = [
  create_qna_topic(
    cur_user: u('user3'), name: '火災が起こった場合の広報課からの避難経路を教えてください。',
    text: '火災が起こった場合の広報課からの避難経路を教えてください。', category_ids: [@qna_cate[1].id]
  ),
  create_qna_topic(
    name: '事務用品の購入について', category_ids: [@qna_cate[0].id],
    text: '事務用品の購入はどこへ申請すれば良いでしょうか。'
  )
]

## -------------------------------------
puts "# qna/post"

def create_qna_post(data)
  create_item(Gws::Qna::Post, data)
end

create_qna_post(
  cur_user: u('user4'), name: 'Re: 火災が起こった場合の広報課からの避難経路を教えてください。',
  text: '防災計画資料をご覧ください。', topic_id: @qna_topics[0].id, parent_id: @qna_topics[0].id
)
