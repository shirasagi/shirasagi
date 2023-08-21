puts "# workflow/form"

def create_workflow_form(data)
  create_item(Gws::Workflow::Form, data)
end

@wf_forms = [
  create_workflow_form(name: '出張申請', order: 10, state: 'public', memo: '出張申請です。'),
  create_workflow_form(name: '稟議書', order: 20, state: 'public', memo: '稟議書です。')
]

@wf_form0_cols = [
  create_column(
    :text, form: @wf_forms[0], name: '出張期間', order: 10, required: 'required',
    tooltips: '出張期間を入力してください。', input_type: 'text'
  ),
  create_column(:text, form: @wf_forms[0], name: '出張先', order: 20, required: 'required', input_type: 'text'),
  create_column(:text, form: @wf_forms[0], name: '目的', order: 30, required: 'required', input_type: 'text'),
  create_column(
    :number, form: @wf_forms[0], name: '必要経費', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
  create_column(:text_area, form: @wf_forms[0], name: '詳細', order: 50, required: 'required'),
]

@wf_form1_cols = [
  create_column(
    :text_area, form: @wf_forms[1], name: '起案内容', order: 10, required: 'required',
    tooltips: '起案内容の詳細説明を入力してください。'
  ),
  create_column(
    :text, form: @wf_forms[1], name: '時期', order: 20, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :text, form: @wf_forms[1], name: '委託行者', order: 30, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :number, form: @wf_forms[1], name: '金額', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
]

## -------------------------------------
puts "# workflow/file"

def create_workflow_file(data)
  create_item(Gws::Workflow::File, data)
end

create_workflow_file(
  cur_user: u('user1'), cur_form: @wf_forms[0], name: '東京出張申請', state: 'closed',
  readable_setting_range: 'select', readable_group_ids: %w(政策課).map { |n| g(n).id },
  workflow_user_id: u('user1').id, workflow_state: 'request', workflow_comment: '東京出張を申請します。',
  workflow_approvers: [
    { level: 1, user_id: u('admin').id, editable: '', state: 'request', comment: ''},
    { level: 2, user_id: u('sys').id, editable: '', state: 'pending', comment: ''}
  ], workflow_required_counts: [false, false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2017/12/14~2017/12/15'),
    @wf_form0_cols[1].serialize_value('東京都庁'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('50000'),
    @wf_form0_cols[4].serialize_value("会議のため、東京都庁に出張します。\r\n飛行機での移動となります。"),
  ]
)

create_workflow_file(
  cur_user: u('user5'), cur_form: @wf_forms[1], name: 'パソコンの購入', state: 'closed',
  readable_setting_range: 'select', readable_group_ids: %w(広報課).map { |n| g(n).id },
  workflow_user_id: u('user5').id, workflow_state: 'request', workflow_comment: 'パソコン購入の稟議です。',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'request', comment: ''},
    { level: 2, user_id: u('sys').id, editable: '', state: 'pending', comment: ''}
  ], workflow_required_counts: [false, false],
  column_values: [
    @wf_form1_cols[0].serialize_value('サポート期間が切れるため、新たなパソコン買い替えを行いたいと思います。'),
    @wf_form1_cols[1].serialize_value('2018年1月'),
    @wf_form1_cols[2].serialize_value("株式会社#{@site_name}"),
    @wf_form1_cols[3].serialize_value('100000'),
  ]
)

create_workflow_file(
  cur_user: u('user5'), cur_form: @wf_forms[1], name: '備品購入', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('user5').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('sys').id, editable: '', state: 'request', comment: '' }
  ], workflow_required_counts: [ false ],
  column_values: [
    @wf_form1_cols[0].serialize_value('事務用品の購入を行いたいと思います。'),
    @wf_form1_cols[1].serialize_value('2018年8月'),
    @wf_form1_cols[2].serialize_value('クロサギ商事'),
    @wf_form1_cols[3].serialize_value('10000'),
  ]
)

create_workflow_file(
  cur_user: u('admin'), cur_form: @wf_forms[1], name: '複合機入れ替え', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('admin').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('sys').id, editable: '', state: 'request', comment: ''}
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form1_cols[0].serialize_value('複合機劣化に伴う入れ替えを申請します。'),
    @wf_form1_cols[1].serialize_value('2018年9月'),
    @wf_form1_cols[2].serialize_value('アオサギ株式会社'),
    @wf_form1_cols[3].serialize_value('1000000'),
  ]
)

create_workflow_file(
  cur_user: u('user1'), cur_form: @wf_forms[0], name: '福岡出張申請', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('user1').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('admin').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2018/10/20 - 2018/10/21'),
    @wf_form0_cols[1].serialize_value('福岡県庁'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('40000'),
    @wf_form0_cols[4].serialize_value("福岡県庁にて〇〇業務の会議があります。"),
  ]
)

create_workflow_file(
  cur_user: u('user2'), cur_form: @wf_forms[1], name: '事務用品購入申請', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('user2').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user4').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form0_cols[0].serialize_value('コピー用紙の購入を申請します。'),
    @wf_form0_cols[1].serialize_value('できるだけ早期'),
    @wf_form0_cols[2].serialize_value('アオサギ株式会社'),
    @wf_form0_cols[3].serialize_value('3000'),
  ]
)

create_workflow_file(
  cur_user: u('user5'), cur_form: @wf_forms[0], name: '山口出張申請', state: 'approve',
  readable_setting_range: 'public',
  workflow_user_id: u('user5').id, workflow_state: 'approve', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'approve', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2018/10/14~2018/10/15'),
    @wf_form0_cols[1].serialize_value('山口県庁'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('20000'),
    @wf_form0_cols[4].serialize_value("会議のため、東京都庁に出張します。\n公用車での移動になります。")
  ]
)

create_workflow_file(
  cur_user: u('user3'), cur_form: @wf_forms[0], name: '青森出張申請', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('user3').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('sys').id, editable: '', state: 'request', comment: ''}
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2018/12/12 - 2018/12/14'),
    @wf_form0_cols[1].serialize_value('青森県庁'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('60000'),
    @wf_form0_cols[4].serialize_value('〇〇業務会議のため青森県庁を訪問します。')
  ]
)

create_workflow_file(
  cur_user: u('user2'), cur_form: @wf_forms[0], name: '大阪出張申請', state: 'approve',
  readable_setting_range: 'public',
  workflow_user_id: u('user2').id, workflow_state: 'approve', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user4').id, editable: '', state: 'approve', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form0_cols[0].serialize_value('2018/11/14 - 2018/11/16'),
    @wf_form0_cols[1].serialize_value('大阪市役所'),
    @wf_form0_cols[2].serialize_value('業務会議のため'),
    @wf_form0_cols[3].serialize_value('20000'),
    @wf_form0_cols[4].serialize_value('〇〇プロジェクトの会議があります。')
  ]
)

create_workflow_file(
  cur_user: u('user4'), cur_form: @wf_forms[1], name: 'AED導入申請', state: 'closed',
  readable_setting_range: 'public',
  workflow_user_id: u('user4').id, workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('sys').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf_form1_cols[0].serialize_value('庁舎内のAEDの追加を申請します。'),
    @wf_form1_cols[1].serialize_value('2019年1月'),
    @wf_form1_cols[2].serialize_value('クロサギ株式会社'),
    @wf_form1_cols[3].serialize_value('10000000'),
  ]
)
