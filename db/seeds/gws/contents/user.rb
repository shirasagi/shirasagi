puts "# user_form"

def create_user_form(data)
  # puts data[:name]
  cond = { site_id: @site._id }
  item = Gws::UserForm.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

def create_user_form_data(data)
  # puts data[:name]
  cond = { site_id: @site._id, user_id: data[:cur_user].id }
  item = Gws::UserFormData.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site)
  puts item.errors.full_messages unless item.save
  item
end

user_form = create_user_form(state: 'public')

user_form_columns = [
  create_column(
    :select, form: user_form, name: '性別', order: 10, required: 'optional',
    tooltips: '性別を選択してください。', select_options: %w(男性 女性)
  ),
  create_column(
    :date, form: user_form, name: '生年月日', order: 20, required: 'optional',
    tooltips: '生年月日を入力してください。'
  ),
  create_column(
    :text, form: user_form, name: '個人携帯電話', order: 30, required: 'optional', input_type: 'tel',
    tooltips: '個人所有の携帯電話番号を入力してください。', place_holder: '090-0000-0000',
    additional_attr: 'pattern="\d{2,4}-\d{3,4}-\d{3,4}"'
  )
]

create_user_form_data(cur_user: u('sys'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1976/12/06'),
  user_form_columns[2].serialize_value('090-0000-0000'),
])
create_user_form_data(cur_user: u('admin'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1980/08/24'),
  user_form_columns[2].serialize_value('090-0000-0001'),
])
create_user_form_data(cur_user: u('user1'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1982/06/21'),
  user_form_columns[2].serialize_value('090-0000-0002'),
])
create_user_form_data(cur_user: u('user2'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1979/10/04'),
  user_form_columns[2].serialize_value('090-0000-0004'),
])
create_user_form_data(cur_user: u('user3'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('男性'),
  user_form_columns[1].serialize_value('1990/08/14'),
  user_form_columns[2].serialize_value('090-0000-0005'),
])
create_user_form_data(cur_user: u('user4'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1967/02/20'),
  user_form_columns[2].serialize_value('090-0000-0006'),
])
create_user_form_data(cur_user: u('user5'), form: user_form, column_values: [
  user_form_columns[0].serialize_value('女性'),
  user_form_columns[1].serialize_value('1992/03/13'),
  user_form_columns[2].serialize_value('090-0000-0007'),
])

## -------------------------------------
puts "# user_title"

def create_user_title(data)
  puts data[:name]
  cond = { group_id: @site._id, name: data[:name] }
  item = Gws::UserTitle.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  puts item.errors.full_messages unless item.save
  item
end

user_titles = [
  create_user_title(name: '部長', code: 'T0100', order: 40),
  create_user_title(name: '課長', code: 'T0200', order: 30),
  create_user_title(name: '係長', code: 'T0300', order: 20),
  create_user_title(name: '主任', code: 'T0400', order: 10)
]

u('sys').add_to_set(title_ids: [user_titles[1].id])
u('admin').add_to_set(title_ids: [user_titles[0].id])
u('user2').add_to_set(title_ids: [user_titles[3].id])
u('user3').add_to_set(title_ids: [user_titles[1].id])
u('user4').add_to_set(title_ids: [user_titles[1].id])
