puts "# tabular/space"

def create_tabular_space(data)
  create_item(Gws::Tabular::Space, data)
end

@tabular_spaces = [
  create_tabular_space(
    cur_site: @site, cur_user: u('sys'), name: "社有車管理", state: "public", order: 100
  ),
  create_tabular_space(
    cur_site: @site, cur_user: u('sys'), name: "レンタル品", state: "public", order: 200
  )
]

puts "# tabular/form"

def create_tabular_form(data)
  item = create_item(Gws::Tabular::Form, data)

  release = Gws::Tabular::FormRelease.new(
    cur_site: @site, cur_space: item.space, cur_form: item, revision: item.revision
  )
  release.save!

  backup_service = Gws::Column::BackupService.new(
    cur_site: @site, cur_user: u('sys'), model: item.class
  )
  backup_service.criteria = item.class.unscoped.where(id: item.id)
  backup_service.filename = release.archive_path
  backup_service.call

  item
end

@tabular_forms = [
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "使用履歴",
    state: "public", order: 100
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "社有車",
    state: "public", order: 200
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "メーカー",
    state: "public", order: 300
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "種類",
    state: "public", order: 400
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "レンタル品",
    state: "public", order: 100
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "種別",
    state: "public", order: 200
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "分類",
    state: "public", order: 300
  )
]

puts "# tabular/column"

def create_tabular_column(data)
  if data[:_type].present?
    model = data[:_type].constantize
  else
    model = Gws::Column::Base
  end
  puts data[:name]
  cond = { site_id: @site._id, form_id: data[:form].id, name: data[:name] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

@tabular_columns = [
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[0], name: "使用日", order: 10,
    required: "required", input_type: "date", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[0], name: "車両", order: 20,
    required: "required", reference_form: @tabular_forms[1], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::EnumField", form: @tabular_forms[0], name: "使用目的", order: 30,
    required: "required", select_options: %w(社用 出退勤 私用), input_type: "radio", index_state: "none",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[0], name: "備考", order: 40,
    required: "required", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::EnumField", form: @tabular_forms[0], name: "事故・損傷", order: 50,
    required: "optional", select_options: %w(なし あり), input_type: "radio", index_state: "none",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[1], name: "表示名", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[1], name: "メーカー", order: 20,
    required: "required", reference_form: @tabular_forms[2], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[1], name: "モデル名", order: 30,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[1], name: "車両番号", order: 40,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[1], name: "種類", order: 50,
    required: "required", reference_form: @tabular_forms[3], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[1], name: "車検期限", order: 60,
    required: "required", input_type: "date", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[2], name: "メーカー", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[2], name: "並び順", order: 20,
    required: "optional", field_type: "integer", min_value: 0.0, index_state: "asc",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[3], name: "種類名", order: 10,
    required: "required", input_type: "single", index_state: "asc", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[3], name: "並び順", order: 20,
    required: "optional", field_type: "integer", min_value: 0.0, index_state: "asc",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[4], name: "使用日", order: 10,
    required: "optional", input_type: "datetime", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "使用目的", order: 20,
    required: "optional", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[4], name: "分類", order: 30,
    required: "required", reference_form: @tabular_forms[6], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "製品名", order: 40,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[4], name: "数量", order: 50,
    required: "optional", field_type: "integer", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::FileUploadField", form: @tabular_forms[4], name: "写真1", order: 60,
    required: "optional", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::FileUploadField", form: @tabular_forms[4], name: "写真2", order: 70,
    required: "optional", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "備考", order: 80,
    required: "optional", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[5], name: "名称", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[5], name: "並び順", order: 20,
    required: "required", field_type: "integer", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[6], name: "分類", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[6], name: "並び順", order: 20,
    required: "required", field_type: "integer", index_state: "none", unique_state: "disabled"
  )
]

puts "# tabular/view"

def create_tabular_view(data)
  if data[:_type].present?
    model = data[:_type].constantize
  else
    model = Gws::Tabular::View::Base
  end
  html ||= File.read("db/seeds/gws/tabular/#{data[:space].name}/#{data[:name]}.template_html.html") rescue nil
  style ||= File.read("db/seeds/gws/tabular/#{data[:space].name}/#{data[:name]}.template_style.html") rescue nil
  data[:template_html] = html if html
  data[:template_style] = style if style
  create_item(model, data)
end

@tabular_views = [
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[0], name: "使用履歴",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    order: 100, default_state: "enabled",
    title_column_ids: [
      @tabular_columns[0].id, @tabular_columns[1].id,
      @tabular_columns[2].id
    ],
    meta_column_ids: [
      @tabular_columns[3].id, @tabular_columns[4].id,
      "updated"
    ],
    orders: [
      { column_id: @tabular_columns[0].id, direction: "asc" },
      { column_id: @tabular_columns[1].id, direction: "asc" }
    ]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[1], name: "社有車",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    order: 200, default_state: "enabled",
    title_column_ids: [
      @tabular_columns[5].id, @tabular_columns[8].id
    ],
    meta_column_ids: [
      @tabular_columns[10].id
    ]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::Liquid", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[1], form: @tabular_forms[4], name: "レンタル品一覧",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    default_state: "enabled", limit_count: 20
  )
]

@tabular_forms.each do |form|
  backup_service = Gws::Column::BackupService.new(
    cur_site: @site, cur_user: u('sys'), model: form.class
  )
  backup_service.criteria = form.class.unscoped.where(id: form.id)
  backup_service.filename = form.current_release.archive_path
  backup_service.call
end

puts "# tabular/file"

def create_tabular_file(data)
  cond = { site_id: @site._id }
  item = Gws::Tabular::File[data[:form].current_release].new(cond)
  item.attributes = data
  item.cur_site ||= @site
  item.cur_user ||= u('admin') if item.respond_to?(:cur_user)
  if item.respond_to?("user_ids=")
    item.user_ids = ([item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = ([item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
  "col_#{@tabular_columns[25].id}": "PC",
  "col_#{@tabular_columns[26].id}": 100
)
@tabular_file_1_6_2 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
  "col_#{@tabular_columns[25].id}": "PC周辺機器",
  "col_#{@tabular_columns[26].id}": 200
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
  "col_#{@tabular_columns[25].id}": "什器",
  "col_#{@tabular_columns[26].id}": 300
)
@tabular_file_1_6_4 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
  "col_#{@tabular_columns[25].id}": "事務用品",
  "col_#{@tabular_columns[26].id}": 400
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
  "col_#{@tabular_columns[25].id}": "その他",
  "col_#{@tabular_columns[26].id}": 500
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "PC本体",
  "col_#{@tabular_columns[24].id}": 100
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "ケーブル類",
  "col_#{@tabular_columns[24].id}": 200
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "付属品類",
  "col_#{@tabular_columns[24].id}": 300
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "デスク",
  "col_#{@tabular_columns[24].id}": 400
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "イス",
  "col_#{@tabular_columns[24].id}": 500
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "コピー機",
  "col_#{@tabular_columns[24].id}": 600
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[5],
  "col_#{@tabular_columns[23].id}": "その他",
  "col_#{@tabular_columns[24].id}": 700
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[4],
  "col_#{@tabular_columns[15].id}": "2025-07-16 09:00",
  "col_#{@tabular_columns[16].id}": "出張のため",
  "col_#{@tabular_columns[17].id}_ids": [@tabular_file_1_6_2.id],
  "col_#{@tabular_columns[18].id}": "Wi-Fiルーター",
  "col_#{@tabular_columns[19].id}": 1,
  "in_col_#{@tabular_columns[20].id}": sh_upload_file('dummy_slide05.png'),
  "in_col_#{@tabular_columns[21].id}": sh_upload_file('dummy_slide08.png')
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[4],
  "col_#{@tabular_columns[15].id}": "2025-07-23 13:39",
  "col_#{@tabular_columns[17].id}_ids": [@tabular_file_1_6_4.id],
  "col_#{@tabular_columns[18].id}": "テプラ",
  "col_#{@tabular_columns[19].id}": 1
)
@tabular_file_0_3_0 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[3],
  "col_#{@tabular_columns[13].id}": "ワゴン",
  "col_#{@tabular_columns[14].id}": 100
)
@tabular_file_0_3_1 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[3],
  "col_#{@tabular_columns[13].id}": "軽自動車",
  "col_#{@tabular_columns[14].id}": 300
)
@tabular_file_0_3_2 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[3],
  "col_#{@tabular_columns[13].id}": "セダン",
  "col_#{@tabular_columns[14].id}": 100
)
@tabular_file_0_2_0 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[2],
  "col_#{@tabular_columns[11].id}": "トヨタ",
  "col_#{@tabular_columns[12].id}": 100
)
@tabular_file_0_2_1 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[2],
  "col_#{@tabular_columns[11].id}": "ホンダ",
  "col_#{@tabular_columns[12].id}": 200
)
@tabular_file_0_2_2 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[2],
  "col_#{@tabular_columns[11].id}": "ダイハツ",
  "col_#{@tabular_columns[12].id}": 300
)
@tabular_file_0_1_0 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[1],
  "col_#{@tabular_columns[5].id}": "トヨタプリウス",
  "col_#{@tabular_columns[6].id}_ids": [@tabular_file_0_2_0.id],
  "col_#{@tabular_columns[7].id}": "プリウス",
  "col_#{@tabular_columns[8].id}": "品川 300 あ 11-11",
  "col_#{@tabular_columns[9].id}_ids": [@tabular_file_0_3_2.id],
  "col_#{@tabular_columns[10].id}": "2025-07-01",
)
@tabular_file_0_1_1 = create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[1],
  "col_#{@tabular_columns[5].id}": "ホンダ アクティバン",
  "col_#{@tabular_columns[6].id}_ids": [@tabular_file_0_2_1.id],
  "col_#{@tabular_columns[7].id}": "アクティバン",
  "col_#{@tabular_columns[8].id}": "品川 500 く 22-22",
  "col_#{@tabular_columns[9].id}_ids": [@tabular_file_0_3_0.id],
  "col_#{@tabular_columns[10].id}": "2025-10-15",
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[1],
  "col_#{@tabular_columns[5].id}": "ダイハツ ハイゼットカーゴ",
  "col_#{@tabular_columns[6].id}_ids": [@tabular_file_0_2_2.id],
  "col_#{@tabular_columns[7].id}": "ハイゼットカーゴ",
  "col_#{@tabular_columns[8].id}": "品川 400 ま 33-33",
  "col_#{@tabular_columns[9].id}_ids": [@tabular_file_0_3_1.id],
  "col_#{@tabular_columns[10].id}": "2024-03-31",
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[0],
  "col_#{@tabular_columns[0].id}": "2025-07-17",
  "col_#{@tabular_columns[1].id}_ids": [@tabular_file_0_1_1.id],
  "col_#{@tabular_columns[2].id}": %w(社用),
  "col_#{@tabular_columns[3].id}": "配達",
  "col_#{@tabular_columns[4].id}": %w(なし)
)
create_tabular_file(
  cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[0],
  "col_#{@tabular_columns[0].id}": "2025-08-01",
  "col_#{@tabular_columns[1].id}_ids": [@tabular_file_0_1_0.id],
  "col_#{@tabular_columns[2].id}": %w(社用),
  "col_#{@tabular_columns[3].id}": "営業",
  "col_#{@tabular_columns[4].id}": %w(なし)
)
