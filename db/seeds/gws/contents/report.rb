puts "# report/category"

def create_report_category(data)
  create_item(Gws::Report::Category, data)
end

@rep_cate = [
  create_report_category(name: '議事録', color: '#3300FF', order: 10),
  create_report_category(name: '報告書', color: '#00FF22', order: 20),
  create_report_category(name: 'イベント報告書です。', color: '#00FF22', order: 30)
]

## -------------------------------------
puts "# report/form"

def create_report_form(data)
  create_item(Gws::Report::Form, data)
end

@rep_forms = [
  create_report_form(
    name: '打ち合わせ議事録', order: 10, state: 'public', memo: '打ち合わせ議事録です。', category_ids: [@rep_cate[0].id]
  ),
  create_report_form(
    name: '出張報告書', order: 20, state: 'public', memo: '出張報告書です。', category_ids: [@rep_cate[1].id]
  ),
  create_report_form(
    name: 'イベント報告書', order: 30, state: 'public', memo: 'イベント報告書です。', category_ids: [@rep_cate[1].id]
  )
]

@rep_form0_cols = [
  create_column(
    :text, name: '打ち合わせ場所', order: 10, required: 'required',
    tooltips: '打ち合わせ場所をん入力してください。', input_type: 'text', form: @rep_forms[0]
  ),
  create_column(
    :date, name: '打ち合わせ日', order: 20, required: 'required',
    tooltips: '打ち合わせ日を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :text, name: '打ち合わせ時間', order: 30, required: 'required',
    tooltips: '打ち合わせ時間を入力してください。', input_type: 'text', form: @rep_forms[0]
  ),
  create_column(
    :text_area, name: '参加者', order: 40, required: 'required',
    tooltips: '打ち合わせ参加者を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :text_area, name: '打ち合わせ内容', order: 50, required: 'required',
    tooltips: '打ち合わせ内容を入力してください。', form: @rep_forms[0]
  ),
  create_column(
    :file_upload, name: '添付ファイル', order: 60, required: 'optional',
    tooltips: '関連資料があればファイルをアップロードしてください。', upload_file_count: 5, form: @rep_forms[0]
  )
]

@rep_form1_cols = [
  create_column(
    :text, name: '出張先', order: 10, required: 'required', input_type: 'text', form: @rep_forms[1]
  ),
  create_column(
    :date, name: '出張日', order: 20, required: 'required', form: @rep_forms[1]
  ),
  create_column(
    :text_area, name: '報告内容', order: 30, required: 'required', form: @rep_forms[1]
  )
]

@rep_form2_cols = [
  create_column(
    :text, name: 'イベント開催場所', order: 10, required: 'required', place_holder: "#{@site_name}公園",
    tooltips: 'イベント開催場所を入力してください。', input_type: 'text', form: @rep_forms[2]
  ),
  create_column(
    :date, name: 'イベント開催日', order: 20, required: 'optional', input_type: 'date',
    tooltips: 'イベント開催日を入力してください。', form: @rep_forms[2]
  ),
  create_column(
    :text_area, name: '参加者', order: 30, required: 'required',
    tooltips: 'イベントの参加者を入力してください。', form: @rep_forms[2]
  ),
  create_column(
    :text_area, name: '報告内容', order: 40, required: 'required',
    tooltips: '報告内容を入力してください。', form: @rep_forms[2]
  ),
  create_column(
    :file_upload, name: '添付ファイル', order: 50, required: 'optional',
    tooltips: '関連資料などをアップロードください。', upload_file_count: 1, form: @rep_forms[2]
  )
]

## -------------------------------------
puts "# report/file"

def create_report_file(data)
  create_item(Gws::Report::File, data)
end

create_report_file(
  cur_form: @rep_forms[0], in_skip_notification_mail: true, name: "第1回#{@site_name}会議打ち合わせ議事録", state: 'public',
  member_ids: %w(admin user1 user3).map { |u| u(u).id }, schedule_ids: [@sch_plan1.id.to_s],
  readable_setting_range: 'select', readable_group_ids: %w(政策課 広報課).map { |n| g(n).id },
  column_values: [
    @rep_form0_cols[0].serialize_value('会議室101'),
    @rep_form0_cols[1].serialize_value((@today - 7.days).strftime('%Y/%m/%d')),
    @rep_form0_cols[2].serialize_value('15:00〜16:00'),
    @rep_form0_cols[3].serialize_value("広報課　斎藤課長\n政策課　白鷺係長"),
    @rep_form0_cols[4].serialize_value("#{@site_name}プロジェクトについての会議を行った。\nかれこれしかじか"),
    @rep_form0_cols[5].serialize_value([])
  ]
)

create_report_file(
  cur_user: u('user1'), cur_form: @rep_forms[1], in_skip_notification_mail: true, name: '東京出張報告', state: 'public',
  member_ids: @users.map(&:id), schedule_ids: [@sch_plan2.id.to_s],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  column_values: [
    @rep_form1_cols[0].serialize_value('東京都庁'),
    @rep_form1_cols[1].serialize_value((@today - 3.days).strftime('%Y/%m/%d')),
    @rep_form1_cols[2].serialize_value("東京都庁で会議のため、出張しました。\nかれこれしかじか。")
  ]
)

create_report_file(
  cur_user: u('user3'), cur_form: @rep_forms[1], in_skip_notification_mail: true, name: '広報イベント報告書', state: 'public',
  member_ids: @users.map(&:id), schedule_ids: [@sch_plan2.id.to_s],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  column_values: [
    @rep_form1_cols[2].serialize_value("#{@site_name}市民会館"),
    @rep_form1_cols[2].serialize_value((@today - 3.days).strftime('%Y/%m/%d')),
    @rep_form1_cols[2].serialize_value("東京都庁で会議のため、出張しました。\nかれこれしかじか。")
  ]
)

create_report_file(
  cur_user: u('user3'), cur_form: @rep_forms[1], in_skip_notification_mail: true, name: '広島出張報告書', state: 'public',
  member_ids: [u("sys").id, u("admin").id, u("user1").id], schedule_ids: [@sch_admin_hiroshima.id.to_s],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  column_values: [
    @rep_form1_cols[0].serialize_value('広島県庁'),
    @rep_form1_cols[1].serialize_value((@today - 3.days).strftime('%Y/%m/%d')),
    @rep_form1_cols[2].serialize_value("広島県庁にて〇〇プロジェクトについての打ち合わせを行いました。")
  ]
)

create_report_file(
  cur_user: u('user3'), cur_form: @rep_forms[0], in_skip_notification_mail: true, name: '5月9日　定例報告会議事録',
  state: 'public',
  member_ids: @users.map(&:id), schedule_ids: [@sch_plan2.id.to_s],
  readable_setting_range: 'select', readable_group_ids: [g('政策課').id],
  column_values: [
    @rep_form0_cols[0].serialize_value(' 大講堂'),
    @rep_form0_cols[1].serialize_value((@today - 3.days).strftime('%Y/%m/%d')),
    @rep_form0_cols[2].serialize_value('14:00 - 16:00'),
    @rep_form0_cols[3].serialize_value("政策課　鈴木 茂\n 広報課　斎藤　拓也\n 管理課　渡辺 和子"),
    @rep_form0_cols[4].serialize_value("定例報告会の打ち合わせ議事録です。")
  ]
)
