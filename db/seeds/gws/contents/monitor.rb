puts "# monitor/category"

def create_monitor_category(data)
  create_item(Gws::Monitor::Category, data)
end

@mon_cate = [
  create_monitor_category(name: '設備', color: '#FF4000', order: 10),
  create_monitor_category(name: 'システム操作', color: '#FFF700', order: 20),
  create_monitor_category(name: 'アンケート', color: '#00FFEE', order: 30)
]

## -------------------------------------
puts "# monitor/topic"

def create_monitor_topic(data)
  create_item(Gws::Monitor::Topic, data)
end

@mon_topics = [
  create_monitor_topic(
    cur_user: u('user4'), name: '共有ファイルに登録できるファイル容量および種類',
    due_date: @now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: '共有ファイルに登録できるファイル容量および種類の制限を教えてください。', category_ids: [@mon_cate[1].id],
    state: 'public', article_state: 'open'
  ),

  create_monitor_topic(
    cur_user: u('user5'), name: '新しい公用車の導入',
    due_date: @now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: "公用車の劣化が進んでおり、買い替えを行うことになりました。\n希望車種などがあれば回答をお願いします。",
    category_ids: [@mon_cate[0].id], state: 'public', article_state: 'open'
  ),
  create_monitor_topic(
    cur_user: u('user4'), name: '庁舎防災設備強化',
    due_date: @now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: "庁舎の防災設備を強化を計画しています。\n各課の設備について回答をお願いします。",
    category_ids: [@mon_cate[0].id], state: 'public', article_state: 'open'
  ),
  create_monitor_topic(
    cur_user: u('user2'), name: 'ワークフローのテンプレート',
    due_date: @now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: 'ワークフフローのテンプレートを増やしたのですが、どなたが担当でしょうか。', category_ids: [@mon_cate[1].id]
  ),
  create_monitor_topic(
    cur_user: u('admin'), name: '企画イベントについてのアンケート',
    due_date: @now.beginning_of_day + 7.days,
    attend_group_ids: [@site.id] + @site.descendants.pluck(:id),
    text: "先日の企画イベントの満足度について回答をお願いします。\n以下からお選びください。\n・非常に良かった\n・よかった\n・普通\n・改善の余地あり\n・廃止した方がよい",
    category_ids: [@mon_cate[1].id]
  ),
]

def create_monitor_post(data)
  create_item(Gws::Monitor::Post, data)
end

create_monitor_post(
  cur_user: u('admin'), name: 'Re: 共有ファイルに登録できるファイル容量および種類',
  due_date: @mon_topics[1].due_date,
  topic_id: @mon_topics[1].id, parent_id: @mon_topics[1].id,
  text: "容量は〇〇MBで制限種類は\n pdf,doc,docs,xls,xlsx,jpg,gif,png を許可しています。"
)
create_monitor_post(
  cur_user: u('admin'), name: 'Re: 新しい公用車の導入',
  due_date: @mon_topics[1].due_date,
  topic_id: @mon_topics[1].id, parent_id: @mon_topics[1].id,
  text: '車室の広いものを希望します。'
)
