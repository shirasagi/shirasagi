puts "# faq/category"

def create_faq_category(data)
  create_item(Gws::Faq::Category, data)
end

@faq_cate = [
  create_faq_category(name: "出張", color: "#6FFF00", order: 10),
  create_faq_category(name: "システム操作", color: "#FFF700", order: 20)
]

## -------------------------------------
puts "# faq/topic"

def create_faq_topic(data)
  create_item(Gws::Faq::Topic, data)
end

@faq_topics = [
  create_faq_topic(
    name: '新しいグループウェアアカウントの発行はどうすればいいですか。', text: 'システム管理者にアカウント発行の申請を行ってください。',
    mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[1].id], readable_setting_range: 'public'
  ),
  create_faq_topic(
    name: '出張申請はどのように行いますか。', text: 'ワークフローに「出張申請」がありますので、必要事項を記入し申請してください。',
    mode: 'thread', permit_comment: 'deny', category_ids: [@faq_cate[0].id], readable_setting_range: 'public'
  )
]
