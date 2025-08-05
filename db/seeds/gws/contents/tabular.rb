puts "# tabular/space"

def create_tabular_space(data)
  create_item(Gws::Tabular::Space, data)
end

@tabular_spaces = [
  create_tabular_space(
    cur_site: @site, cur_user: u('sys'), name: "テストDB", state: "public",
    readable_group_ids: [g("政策課").id]
  ),
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
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "画像",
    state: "closed", readable_group_ids: [g("政策課").id]
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "名前",
    state: "public", readable_group_ids: [g("政策課").id]
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], revision: 0, name: "説明",
    state: "public", readable_group_ids: [g("政策課").id]
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "使用履歴",
    state: "public", order: 100
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "社有車",
    state: "public", order: 200
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "メーカー",
    state: "closed", order: 300
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], revision: 0, name: "種類",
    state: "public", order: 400
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[2], revision: 0, name: "レンタル品",
    state: "public", order: 100
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[2], revision: 0, name: "種別",
    state: "public", order: 200
  ),
  create_tabular_form(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[2], revision: 0, name: "分類",
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
    _type: "Gws::Tabular::Column::LookupField", form: @tabular_forms[0], name: "ルックアップ", order: 10,
    required: "required", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[0], name: "参照型（さん）", order: 20,
    required: "required", reference_form: @tabular_forms[1], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::FileUploadField", form: @tabular_forms[0], name: "ファイルアップロード", order: 30,
    required: "required", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[0], name: "数値型", order: 40,
    required: "required", field_type: "integer", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[0], name: "日付時刻型", order: 50,
    required: "required", input_type: "datetime", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[0], name: "テキスト型", order: 60,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::EnumField", form: @tabular_forms[0], name: "列挙型", order: 70,
    required: "required", select_options: %w(選択肢1 選択肢2 選択肢3), input_type: "radio",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[0], name: "参照型", order: 80,
    required: "required", reference_type: "one_to_one", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[1], name: "テキスト型（なまえ）", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[2], name: "テキスト型", order: 10,
    required: "required", input_type: "multi_html", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[3], name: "使用日", order: 10,
    required: "required", input_type: "date", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[3], name: "車両", order: 20,
    required: "required", reference_form: @tabular_forms[4], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::EnumField", form: @tabular_forms[3], name: "使用目的", order: 30,
    required: "required", select_options: %w(社用 出退勤 私用), input_type: "radio", index_state: "none",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[3], name: "備考", order: 40,
    required: "required", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::EnumField", form: @tabular_forms[3], name: "事故・損傷", order: 50,
    required: "optional", select_options: %w(なし あり), input_type: "radio", index_state: "none",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "表示名", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[4], name: "メーカー", order: 20,
    required: "required", reference_form: @tabular_forms[5], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "モデル名", order: 30,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[4], name: "車両番号", order: 40,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[4], name: "種類", order: 50,
    required: "required", reference_form: @tabular_forms[6], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[4], name: "車検期限", order: 60,
    required: "required", input_type: "date", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[5], name: "メーカー", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[5], name: "並び順", order: 20,
    required: "optional", field_type: "integer", min_value: 0.0, index_state: "asc",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[6], name: "種類名", order: 10,
    required: "required", input_type: "single", index_state: "asc", unique_state: "enabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[6], name: "並び順", order: 20,
    required: "optional", field_type: "integer", min_value: 0.0, index_state: "asc",
    unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::DateTimeField", form: @tabular_forms[7], name: "使用日", order: 10,
    required: "optional", input_type: "datetime", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[7], name: "使用目的", order: 20,
    required: "optional", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::ReferenceField", form: @tabular_forms[7], name: "分類", order: 30,
    required: "required", reference_form: @tabular_forms[9], reference_type: "one_to_one",
    index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[7], name: "製品名", order: 40,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[7], name: "数量", order: 50,
    required: "optional", field_type: "integer", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::FileUploadField", form: @tabular_forms[7], name: "写真1", order: 60,
    required: "optional", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::FileUploadField", form: @tabular_forms[7], name: "写真2", order: 70,
    required: "optional", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[7], name: "備考", order: 80,
    required: "optional", input_type: "multi", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[8], name: "名称", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[8], name: "並び順", order: 20,
    required: "required", field_type: "integer", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::TextField", form: @tabular_forms[9], name: "分類", order: 10,
    required: "required", input_type: "single", index_state: "none", unique_state: "disabled"
  ),
  create_tabular_column(
    _type: "Gws::Tabular::Column::NumberField", form: @tabular_forms[9], name: "並び順", order: 20,
    required: "required", field_type: "integer", index_state: "none", unique_state: "disabled"
  )
]

@tabular_columns[0].set(reference_column_id: @tabular_columns[1].id)

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
    _type: "Gws::Tabular::View::Liquid", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[1], name: "既定",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    default_state: "disabled",
    readable_group_ids: [g("政策課").id]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::Liquid", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[0], name: "画像メイン",
    authoring_permissions: %w(read), state: "public",
    default_state: "disabled",
    readable_group_ids: [g("政策課").id]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[2], name: "説明リスト",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    default_state: "disabled", title_column_ids: %w(updated created deleted updated_or_deleted),
    meta_column_ids: %w(updated created updated_or_deleted),
    readable_group_ids: [g("政策課").id]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[0], form: @tabular_forms[0], name: "画像リスト",
    authoring_permissions: %w(read), state: "public",
    default_state: "disabled", title_column_ids: %w(updated deleted),
    meta_column_ids: %w(updated deleted),
    readable_group_ids: [g("政策課").id]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[1], form: @tabular_forms[3], name: "使用履歴",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    order: 100, default_state: "enabled",
    title_column_ids: [
      @tabular_columns[10].id, @tabular_columns[11].id,
      @tabular_columns[12].id
    ],
    meta_column_ids: [
      @tabular_columns[13].id, @tabular_columns[14].id,
      "updated"
    ],
    orders: [
      { column_id: @tabular_columns[10].id, direction: "asc" },
      { column_id: @tabular_columns[11].id, direction: "asc" }
    ]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::List", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[1], form: @tabular_forms[4], name: "社有車",
    authoring_permissions: %w(delete download_all edit import read), state: "public",
    order: 200, default_state: "enabled",
    title_column_ids: [
      @tabular_columns[15].id, @tabular_columns[18].id
    ],
    meta_column_ids: [
      @tabular_columns[20].id
    ]
  ),
  create_tabular_view(
    _type: "Gws::Tabular::View::Liquid", cur_site: @site, cur_user: u('sys'),
    space: @tabular_spaces[2], form: @tabular_forms[7], name: "レンタル品一覧",
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
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

@tabular_files = [
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[2],
    "col_#{@tabular_columns[9].id}": "<p>これはテストです1</p>"
  ),
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[0], form: @tabular_forms[2],
    "col_#{@tabular_columns[9].id}": "<p>これはテストです2</p>"
  ),
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[3],
    "col_#{@tabular_columns[10].id}": "2025-07-17",
    "col_#{@tabular_columns[12].id}": %w(社用),
    "col_#{@tabular_columns[13].id}": "配達",
    "col_#{@tabular_columns[14].id}": %w(なし)
  ),
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[3],
    "col_#{@tabular_columns[10].id}": "2025-08-01",
    "col_#{@tabular_columns[12].id}": %w(社用),
    "col_#{@tabular_columns[13].id}": "営業",
    "col_#{@tabular_columns[14].id}": %w(なし)
  )
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
    "col_#{@tabular_columns[23].id}": "ワゴン",
    "col_#{@tabular_columns[24].id}": 100,
  ),
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
    "col_#{@tabular_columns[23].id}": "軽自動車",
    "col_#{@tabular_columns[24].id}": 300,
  ),
  create_tabular_file(
    cur_site: @site, cur_user: u('sys'), space: @tabular_spaces[1], form: @tabular_forms[6],
    "col_#{@tabular_columns[23].id}": "セダン",
    "col_#{@tabular_columns[24].id}": 100,
  ),
]
