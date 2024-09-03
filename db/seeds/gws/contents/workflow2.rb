puts "# workflow2/form/category"

def create_workflow2_form_category(data)
  create_item(Gws::Workflow2::Form::Category, data)
end

@wf2_categories = [
  create_workflow2_form_category(name: '職種', order: 110),
  create_workflow2_form_category(name: '職種/全職員', order: 120),
  create_workflow2_form_category(name: '職種/事務一般', order: 130)
]

## -------------------------------------
puts "# workflow2/form/purpose"

def create_workflow2_form_purpose(data)
  create_item(Gws::Workflow2::Form::Purpose, data)
end

@wf2_purposes = [
  create_workflow2_form_purpose(name: '手続き/出張', order: 110),
  create_workflow2_form_purpose(name: '手続き/税・料', order: 120),
  create_workflow2_form_purpose(name: '手続き/経費', order: 130),
  create_workflow2_form_purpose(name: '情報/ネットワーク', order: 210),
  create_workflow2_form_purpose(name: '情報/ライセンス', order: 220),
  create_workflow2_form_purpose(name: '生活/給付金', order: 310),
  create_workflow2_form_purpose(name: '生活/個人情報変更', order: 320)
]

## -------------------------------------
puts "# workflow2/form/application"

def create_workflow2_form_application(data)
  create_item(Gws::Workflow2::Form::Application, data)
end

@wf2_apps = [
  create_workflow2_form_application(
    name: '出張申請', order: 10, state: 'public', agent_state: 'enabled', memo: '出張申請です。',
    category_ids: [ @wf2_categories[1].id ], purpose_ids: [ @wf2_purposes[0].id ]
  ),
  create_workflow2_form_application(
    name: '稟議書', order: 20, state: 'public', agent_state: 'enabled', memo: '稟議書です。',
    category_ids: [ @wf2_categories[1].id ], purpose_ids: [ @wf2_purposes[2].id ]
  )
]

@wf2_app0_cols = [
  create_column(
    :text, form: @wf2_apps[0], name: '出張期間', order: 10, required: 'required',
    tooltips: '出張期間を入力してください。', input_type: 'text'
  ),
  create_column(:text, form: @wf2_apps[0], name: '出張先', order: 20, required: 'required', input_type: 'text'),
  create_column(:text, form: @wf2_apps[0], name: '目的', order: 30, required: 'required', input_type: 'text'),
  create_column(
    :number, form: @wf2_apps[0], name: '必要経費', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
  create_column(:text_area, form: @wf2_apps[0], name: '詳細', order: 50, required: 'required'),
]

@wf2_app1_cols = [
  create_column(
    :text_area, form: @wf2_apps[1], name: '起案内容', order: 10, required: 'required',
    tooltips: '起案内容の詳細説明を入力してください。'
  ),
  create_column(
    :text, form: @wf2_apps[1], name: '時期', order: 20, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :text, form: @wf2_apps[1], name: '委託行者', order: 30, required: 'optional',
    tooltips: '購入、採用時期がある場合は入力してください。', input_type: 'text'
  ),
  create_column(
    :number, form: @wf2_apps[1], name: '金額', order: 40, required: 'optional',
    postfix_label: '円', minus_type: 'normal'
  ),
]

## -------------------------------------
puts "# workflow2/form/external"

def create_workflow2_form_external(data)
  create_item(Gws::Workflow2::Form::External, data)
end

create_workflow2_form_external(
  name: 'マイナンバーカードの健康保険証利用について', order: 1010, state: 'public', url: "https://www.digital.go.jp/policies/mynumber/faq-insurance-card",
  category_ids: [ @wf2_categories[1].id ], purpose_ids: [ @wf2_purposes[6].id ]
)
create_workflow2_form_external(
  name: 'マイナポータルによる公金受取口座の登録方法', order: 1020, state: 'public', url: "https://www.digital.go.jp/policies/account_registration_mynaportal",
  category_ids: [ @wf2_categories[1].id ], purpose_ids: [ @wf2_purposes[1].id ]
)

## -------------------------------------
puts "# workflow2/file"

def create_workflow2_file(data)
  item = Gws::Workflow2::File.new(site: @site)
  item.attributes = data
  item.cur_site ||= @site
  item.cur_user ||= data[:workflow_user] if item.respond_to?(:cur_user=)
  item.name ||= data[:cur_form].new_file_name
  item.destination_treat_state ||= "no_need_to_treat"
  item.update_workflow_user(@site, data[:workflow_user])
  item.update_workflow_agent(@site, nil)
  puts item.name
  puts item.errors.full_messages unless item.save
  item
end

create_workflow2_file(
  cur_user: u('user1'), cur_form: @wf2_apps[0],
  workflow_user: u('user1'), workflow_state: 'request', workflow_comment: '東京出張を申請します。',
  workflow_approvers: [
    { level: 1, user_id: u('admin').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('2024/12/14~2024/12/15'),
    @wf2_app0_cols[1].serialize_value('東京都庁'),
    @wf2_app0_cols[2].serialize_value('業務会議のため'),
    @wf2_app0_cols[3].serialize_value('50000'),
    @wf2_app0_cols[4].serialize_value("会議のため、東京都庁に出張します。\r\n飛行機での移動となります。"),
  ]
)

create_workflow2_file(
  cur_user: u('user5'), cur_form: @wf2_apps[1],
  workflow_user: u('user5'), workflow_state: 'request', workflow_comment: 'パソコン購入の稟議です。',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app1_cols[0].serialize_value('サポート期間が切れるため、新たなパソコン買い替えを行いたいと思います。'),
    @wf2_app1_cols[1].serialize_value('2025年1月'),
    @wf2_app1_cols[2].serialize_value("株式会社#{@site_name}"),
    @wf2_app1_cols[3].serialize_value('100000'),
  ]
)

create_workflow2_file(
  cur_user: u('user5'), cur_form: @wf2_apps[1],
  workflow_user: u('user5'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'request', comment: '' }
  ], workflow_required_counts: [ false ],
  column_values: [
    @wf2_app1_cols[0].serialize_value('事務用品の購入を行いたいと思います。'),
    @wf2_app1_cols[1].serialize_value('2025年8月'),
    @wf2_app1_cols[2].serialize_value('クロサギ商事'),
    @wf2_app1_cols[3].serialize_value('10000'),
  ]
)

create_workflow2_file(
  cur_user: u('admin'), cur_form: @wf2_apps[1],
  workflow_user: u('admin'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('admin').id, editable: '', state: 'request', comment: ''}
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app1_cols[0].serialize_value('複合機劣化に伴う入れ替えを申請します。'),
    @wf2_app1_cols[1].serialize_value('2025年9月'),
    @wf2_app1_cols[2].serialize_value('アオサギ株式会社'),
    @wf2_app1_cols[3].serialize_value('1000000'),
  ]
)

create_workflow2_file(
  cur_user: u('user1'), cur_form: @wf2_apps[0],
  workflow_user: u('user1'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('admin').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('2025/10/20 - 2025/10/21'),
    @wf2_app0_cols[1].serialize_value('福岡県庁'),
    @wf2_app0_cols[2].serialize_value('業務会議のため'),
    @wf2_app0_cols[3].serialize_value('40000'),
    @wf2_app0_cols[4].serialize_value("福岡県庁にて〇〇業務の会議があります。"),
  ]
)

create_workflow2_file(
  cur_user: u('user2'), cur_form: @wf2_apps[1],
  workflow_user: u('user2'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user4').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('コピー用紙の購入を申請します。'),
    @wf2_app0_cols[1].serialize_value('できるだけ早期'),
    @wf2_app0_cols[2].serialize_value('アオサギ株式会社'),
    @wf2_app0_cols[3].serialize_value('3000'),
  ]
)

create_workflow2_file(
  cur_user: u('user5'), cur_form: @wf2_apps[0],
  workflow_user: u('user5'), workflow_state: 'approve', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'approve', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('2025/10/14~2025/10/15'),
    @wf2_app0_cols[1].serialize_value('山口県庁'),
    @wf2_app0_cols[2].serialize_value('業務会議のため'),
    @wf2_app0_cols[3].serialize_value('20000'),
    @wf2_app0_cols[4].serialize_value("会議のため、東京都庁に出張します。\n公用車での移動になります。")
  ]
)

create_workflow2_file(
  cur_user: u('user3'), cur_form: @wf2_apps[0],
  workflow_user: u('user3'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user3').id, editable: '', state: 'request', comment: ''}
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('2025/12/12 - 2025/12/14'),
    @wf2_app0_cols[1].serialize_value('青森県庁'),
    @wf2_app0_cols[2].serialize_value('業務会議のため'),
    @wf2_app0_cols[3].serialize_value('60000'),
    @wf2_app0_cols[4].serialize_value('〇〇業務会議のため青森県庁を訪問します。')
  ]
)

create_workflow2_file(
  cur_user: u('user2'), cur_form: @wf2_apps[0],
  workflow_user: u('user2'), workflow_state: 'approve', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user4').id, editable: '', state: 'approve', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app0_cols[0].serialize_value('2025/11/14 - 2025/11/16'),
    @wf2_app0_cols[1].serialize_value('大阪市役所'),
    @wf2_app0_cols[2].serialize_value('業務会議のため'),
    @wf2_app0_cols[3].serialize_value('20000'),
    @wf2_app0_cols[4].serialize_value('〇〇プロジェクトの会議があります。')
  ]
)

create_workflow2_file(
  cur_user: u('user4'), cur_form: @wf2_apps[1],
  workflow_user: u('user4'), workflow_state: 'request', workflow_comment: '',
  workflow_approvers: [
    { level: 1, user_id: u('user4').id, editable: '', state: 'request', comment: ''},
  ], workflow_required_counts: [false],
  column_values: [
    @wf2_app1_cols[0].serialize_value('庁舎内のAEDの追加を申請します。'),
    @wf2_app1_cols[1].serialize_value('2026年1月'),
    @wf2_app1_cols[2].serialize_value('クロサギ株式会社'),
    @wf2_app1_cols[3].serialize_value('10000000'),
  ]
)
