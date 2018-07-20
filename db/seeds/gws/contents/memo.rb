## -------------------------------------
## Memo

def memo_signature(user)
  hr = "-" * 52
  group = user.gws_main_group(@site)
  "#{hr}\n#{group.name.tr('/', '　')}\n#{user.name}\n電話番号：00−0000−0000\n#{hr}"
end

## -------------------------------------
puts "# memo/folder"

def create_memo_folder(user, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: user.id, name: data[:name] }
  item = Gws::Memo::Folder.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

@memo_folders = []
@memo_folders << create_memo_folder(u('sys'), name: "#{@site_name}プロジェクト", order: 10)
@memo_folders << create_memo_folder(u('sys'), name: "イベント", order: 20)
@memo_folders << create_memo_folder(u('sys'), name: "サイト管理者から", order: 30)

%w(admin user1 user2 user3 user4 user5).each do |user_name|
  @memo_folders << create_memo_folder(u(user_name), name: "#{@site_name}プロジェクト", order: 10)
  @memo_folders << create_memo_folder(u(user_name), name: "イベント", order: 20)
  @memo_folders << create_memo_folder(u(user_name), name: "システム管理者から", order: 30)
end

def memo_folder(user, name)
  @memo_folders.find { |folder| folder.user_id == user.id && folder.name == name }
end

## -------------------------------------
puts "# memo/filters"

def create_memo_filter(user, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: user.id, name: data[:name] }
  item = Gws::Memo::Filter.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

create_memo_filter u('sys'), name: "#{@site_name}プロジェクト", subject: "#{@site_name}プロジェクト", order: 10,
  action: 'move', folder_id: @memo_folders[0].id
create_memo_filter u('sys'), name: "イベント", subject: "イベント", order: 20,
  action: 'move', folder_id: @memo_folders[1].id
create_memo_filter u('sys'), name: "サイト管理者から", from_member_ids: [u('admin').id], order: 30,
  action: 'move', folder_id: @memo_folders[2].id

%w(admin user1 user2 user3 user4 user5).each_with_index do |user_name, idx|
  create_memo_filter u(user_name), name: "#{@site_name}プロジェクト", subject: "#{@site_name}プロジェクト", order: 10,
    action: 'move', folder_id: @memo_folders[idx*3 + 3].id
  create_memo_filter u(user_name), name: "イベント", subject: "イベント", order: 20,
    action: 'move', folder_id: @memo_folders[idx*3 + 4].id
  create_memo_filter u(user_name), name: "システム管理者から", from_member_ids: [u('sys').id], order: 30,
    action: 'move', folder_id: @memo_folders[idx*3 + 5].id
end

## -------------------------------------
puts "# memo/signatures"

def create_memo_signature(user, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: user.id, name: data[:name] }
  item = Gws::Memo::Signature.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

%w(sys admin user1 user2 user3 user4 user5).each do |user_name|
  user = u(user_name)
  create_memo_signature u(user_name), name: user.name, default: 'enabled',
    text: memo_signature(user)
end

## -------------------------------------
puts "# memo/templates"

def create_memo_template(user, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: user.id, name: data[:name] }
  item = Gws::Memo::Template.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

create_memo_template u('admin'), name: "お電話がありました。", order: 10,
  text: "〇〇さん\n\n〇〇株式会社 〇〇様よりお電話がありました。\n折り返しご連絡をお願いします。",
  group_ids: [g('政策課').id], user_ids: [u('admin').id]

## -------------------------------------
puts "# memo/lists"

def create_memo_list(user, data)
  puts data[:name]
  cond = { site_id: @site._id, user_id: user.id, name: data[:name] }
  item = Gws::Memo::List.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

user = u('sys')
@memo_lists = [
  create_memo_list(u('sys'), name: "システム関連のお知らせ",
    sender_name: user.name, signature: memo_signature(user),
    member_group_ids: @groups.map(&:id),
    group_ids: [g('政策課').id], user_ids: [u('sys').id]),

  create_memo_list(u('sys'), name: "〇〇の告知",
    sender_name: "山田", signature: memo_signature(user),
    member_group_ids: @groups.map(&:id),
    group_ids: [g('政策課').id], user_ids: [u('sys').id])
]

def create_memo_list_message(user, data)
  puts data[:name]
  cond = { site_id: @site._id, subject: data[:subject] }
  item = Gws::Memo::ListMessage.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: user)
  puts item.errors.full_messages unless item.save
  item
end

create_memo_list_message(
  u("sys"), list_id: @memo_lists[0].id, subject: "システムメンテナンスを実施します。",
  state: "public", format: "text",
  text: [
    "○月○日○時から○時の間、システムメンテナンスを実施予定です。",
    "詳細は追って連絡しますが、日時に不都合のある方はシステム管理者までご相談ください。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "システム管理者",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [
    u("sys").id, u("admin").id, u("user1").id, u("user2").id, u("user3").id,
    u("user4").id, u("user5").id
  ],
  seen: {
    u('sys').id.to_s => @now,
    u('admin').id.to_s => @now,
    u('user1').id.to_s => @now,
    u('user4').id.to_s => @now,
    u('user5').id.to_s => @now
  }
)

## -------------------------------------
puts "# memo/messages"

filepath = "db/seeds/gws/files/file.pdf"

def create_message(data)
  model = Gws::Memo::Message

  puts data[:subject]
  cond = { site_id: @site._id, subject: data[:subject] }
  item = model.find_or_initialize_by(cond)
  item.attributes = data.reverse_merge(cur_site: @site, cur_user: u('admin'))
  if item.respond_to?("user_ids=")
    item.user_ids = (Array[item.user_ids].flatten.compact + [item.cur_user.id]).uniq
  end
  if item.respond_to?("group_ids=")
    item.group_ids = (Array[item.group_ids].flatten.compact + item.cur_user.group_ids).uniq
  end
  puts item.errors.full_messages unless item.save
  item
end

create_message(
  cur_user: u("user4"), subject: "防災訓練の資料", state: "public", format: "text",
  text: [
    "渡辺さん",
    "",
    "防災訓練の資料作成をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　危機管理部 管理課",
    "伊藤　幸子",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("user2").id]
)

new_ss_files(filepath, cur_user: u("sys"), filename: "file3.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("sys"), subject: "本庁舎一斉停電のお知らせ", state: "public", format: "text",
    text: [
      "各位\n\nお疲れ様です。",
      "",
      "以下の通り本庁舎の一斉停電を予定しています。",
      "作業を予定されている方は調整をお願いします。",
      "",
      "・日時",
      "　○月○日（月）10時～11時",
      "・場所",
      "　本庁舎全館",
      "",
      "----------------------------------------------------",
      "#{@site_name}市　企画政策部　政策課",
      "システム管理者",
      "Email：sys@demo.ss-proj.org",
      "〒000-0000　大鷺県#{@site_name}市小鷺町1丁目1番地1号",
      "電話番号：00－0000－0000",
      "----------------------------------------------------",
    ].join("\n"),
    in_to_members: [
      u("sys").id, u("admin").id, u("user1").id, u("user2").id, u("user3").id,
      u("user4").id, u("user5").id
    ],
    file_ids: [file.id]
  )
end

new_ss_files(filepath, cur_user: u("user1"), filename: "file4.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("user1"), subject: "政策課内の座席配置変更", state: "public", format: "text",
    text: [
      "政策課各位",
      "",
      "○月○日に政策課内の座席配置変更を実施したいと思います。",
      "ご協力よろしくお願いします。",
      "",
      "----------------------------------------------------",
      "#{@site_name}市　企画政策部　政策課",
      "鈴木 茂",
      "電話番号：00−0000−0000",
      "----------------------------------------------------",
    ].join("\n"),
    in_to_members: [u("sys").id, u("admin").id, u("user1").id], priority: '2',
    file_ids: [file.id]
  )
end

new_ss_files(filepath, cur_user: u("user2"), filename: "file5.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("user2"), subject: "防災訓練", state: "public", format: "text",
    text: [
      "職員各位",
      "",
      "お疲れ様です。危機管理部 管理課　渡辺です。",
      "",
      "○月○日9時〜12時に本庁舎全館で防災訓練を実施します。",
      "日程調整をお願いします。",
      "詳細は添付資料をご確認ください。",
      "",
      "----------------------------------------------------",
      "#{@site_name}市　危機管理部 管理課",
      "渡辺　和子",
      "電話番号：00−0000−0000",
      "----------------------------------------------------",
    ].join("\n"),
    in_to_members: [u("sys").id, u("admin").id, u("user1").id, u("user3").id, u("user4").id], priority: '1',
    file_ids: [file.id]
  )
end

create_message(
  cur_user: u("sys"), subject: "システムメンテナンスを実施します。 ", state: "public", format: "text",
  text: [
    "○月○日○時から○時の間、システムメンテナンスを実施予定です。",
    "詳細は追って連絡しますが、日時に不都合のある方はシステム管理者までご相談ください。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "システム管理者",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("sys").id]
)
create_message(
  cur_user: u("user1"), subject: "[お電話がありました]#{@site_name}商事　山本様 ", state: "public", format: "text",
  text: [
    "システム管理者さん",
    "",
    "#{@site_name}商事 山本様よりお電話がありました。",
    "あらためてご連絡をいただけるそうです。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "鈴木 茂",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("sys").id], priority: '3'
)
create_message(
  cur_user: u("admin"), subject: "サイト改善プロジェクト", state: "public", format: "text",
  text: [
    "#{@site_name}市ホームページの改善プロジェクトを電子会議室に立ち上げました。",
    "ご意見・要望など投稿ください。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "サイト管理者",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("sys").id, u("admin").id, u("user1").id, u("user2").id, u("user3").id,
                  u("user4").id, u("user5").id
  ], priority: '3'
)
new_ss_files(filepath, cur_user: u("sys"), filename: "file6.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("sys"), subject: "クロサギ放送の取材のついて", state: "public", format: "text",
    text: [
      "お疲れ様です。",
      "",
      "#{@site_name}市の広報活動について、クロサギ放送様からインタビュー取材を受ける予定です。",
      "部長にも、取材が来ますので当日は在席をお願いします。",
      "",
      "・日時",
      "　○月○日（水）14時",
      "・場所",
      "　広報課内",
      "・インタビュー内容",
      "　#{@site_name}市の広報活動について",
      "・参加予定",
      "",
      "　クロサギ放送　吉田様",
      "----------------------------------------------------",
      "#{@site_name}市　企画政策部　広報課",
      "斎藤　拓也",
      "",
      "Email：user3@demo.ss-proj.org",
      "〒000-0000　大鷺県#{@site_name}市小鷺町1丁目1番地1号",
      "電話番号：00－0000－0000",
      "----------------------------------------------------",
    ].join("\n"),
    in_to_members: [u("admin").id, u("user3").id],
    file_ids: [file.id]
  )
end
create_message(
  cur_user: u("admin"), subject: "[お電話がありました]アオサギ株式会社　田中様 ", state: "public", format: "text",
  text: [
    "鈴木さん",
    "",
    "アオサギ株式会社 田中様よりお電話がありました。",
    "折り返しご連絡をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "サイト管理者",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("user1").id]
)
create_message(
  cur_user: u("user4"), subject: "[お電話がありました]株式会社#{@site_name}　小野様 ", state: "public", format: "text",
  text: [
    "渡辺さん",
    "",
    "株式会社#{@site_name} 小野様よりお電話がありました。",
    "折り返しご連絡をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　危機管理部 管理課",
    "伊藤　幸子",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
   ].join("\n"),
  in_to_members: [u("user2").id], priority: '1'
)
create_message(
  cur_user: u("user5"), subject: "[お電話がありました]アオサギ商事 三木様 ", state: "public", format: "text",
  text: [
    "斎藤さん",
    "",
    "アオサギ商事 三木様よりお電話がありました。",
    "折り返しご連絡をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　広報課",
    "高橋　清",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("user3").id]
)
create_message(
  cur_user: u("user2"), subject: "[お電話がありました]クロサギ支所　吉田さん ", state: "public", format: "text",
  text: [
    "伊藤さん",
    "",
    "クロサギ支所　吉田さんからお電話がありました。",
    "折り返しご連絡をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　危機管理部 管理課",
    "渡辺　和子",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("user4").id]
)
create_message(
  cur_user: u("user3"), subject: "[お電話がありました]アオサギ支所　中村さん ", state: "public", format: "text",
  text: [
    "高橋さん",
    "",
    "アオサギ支所　中村さんよりお電話がありました。",
    "折り返しご連絡をお願いします。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　広報課",
    "斎藤　拓也",
    "電話番号：00−0000−0000",
    "----------------------------------------------------",
  ].join("\n"),
  in_to_members: [u("user5").id]
)
new_ss_files(filepath, cur_user: u("sys"), filename: "file7.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("sys"), subject: "システム操作研修のお知らせ", state: "public", format: "text",
    text: "#{@site_name}プロジェクトの会議資料作成は進んでいますか。", priority: '1',
    to_member_name: "伊藤 幸子 (user4); 渡辺 和子 (user2); 高橋 清 (user5); 斎藤　拓也 (user3); 鈴木 茂 (user1)",
    member_ids: [u("user1").id, u("user2").id, u("user3").id, u("user4").id, u("user5").id],
    in_to_members: [u("user1").id, u("user2").id, u("user3").id, u("user4").id, u("user5").id, u("admin").id],
    path: {
      u("sys").id.to_s => memo_folder(u("sys"), "#{@site_name}プロジェクト").id,
      u("admin").id.to_s => memo_folder(u("admin"), "#{@site_name}プロジェクト").id,
      u("user1").id.to_s => memo_folder(u("user1"), "#{@site_name}プロジェクト").id,
      u("user3").id.to_s => memo_folder(u("user3"), "#{@site_name}プロジェクト").id,
      u("user5").id.to_s => memo_folder(u("user5"), "#{@site_name}プロジェクト").id
    },
    file_ids: [file.id]
  )
end
new_ss_files(filepath, cur_user: u("user1"), filename: "file8.pdf", model: "ss/temp_file", state: "closed").tap do |file|
  create_message(
    cur_user: u("user1"), subject: "Re: 地域振興イベントの計画 ", state: "public", format: "text",
    text: [
      "承知しました。",
      "イベント一ヶ月前の○月○日までに資料を作成します。",
      "",
      "----------------------------------------------------",
      "#{@site_name}市　企画政策部　政策課",
      "鈴木 茂",
      "電話番号：00−0000−0000",
      "----------------------------------------------------",
      "",
      "地域振興イベントの計画をお願いできますか。",
    ].join("\n"),
    to_member_name: "地域振興イベント",
    member_ids: [u("sys").id, u("admin").id, u("user1").id],
    in_to_members: [u("sys").id, u("user1").id],
    path: {
      u("sys").id.to_s => memo_folder(u("sys"), "イベント").id,
      u("admin").id.to_s => memo_folder(u("admin"), "イベント").id,
      u("user1").id.to_s => memo_folder(u("user1"), "イベント").id,
      u("user3").id.to_s => memo_folder(u("user3"), "イベント").id,
      u("user5").id.to_s => memo_folder(u("user5"), "イベント").id
    },
    file_ids: [file.id]
  )
end
create_message(
  cur_user: u("admin"), subject: "地域振興イベント", state: "public", format: "text",
  text: [
    "鈴木さん",
    "",
    "今月開催の地域振興イベントの計画書の作成をお願いできますか。",
    "",
    "----------------------------------------------------",
    "#{@site_name}市　企画政策部　政策課",
    "サイト管理者\n電話番号：00−0000−0000",
    "----------------------------------------------------"
  ].join("\n"),
  to_member_name: "地域振興イベント",
  member_ids: [u("admin").id, u("user1").id, u("user3").id, u("user5").id],
  in_to_members: [u("user1").id], priority: '2',
  in_cc_members: [u("sys").id],
  path: {
    u("sys").id.to_s => memo_folder(u("sys"), "イベント").id,
    u("admin").id.to_s => memo_folder(u("admin"), "イベント").id,
    u("user1").id.to_s => memo_folder(u("user1"), "イベント").id,
    u("user3").id.to_s => memo_folder(u("user3"), "イベント").id,
    u("user5").id.to_s => memo_folder(u("user5"), "イベント").id
  }
)

#   作りかけ
# ・見本サイトでは個人アドレス帳を用いて送信しているが、個人アドレス帳はWebメールの」シードで登録されるため、そのままではシードの登録が難しい。
# ・組織アドレス帳に変更して、シードを作成しようかとも思ったが、現状の組織アドレス帳にアドレスを登録すると同名のレコードが多数並ぶこととなり、見栄えが非常に悪い。
# ・まずは、組織アドレス帳の仕様や動作を見直し、改善した上で、以下のシードを対応する必要がある。
#
# create_message(
#   cur_user: u("user3"), subject: "地域振興イベント資料", state: "public", format: "text",
#   text: "地域振興イベント関係者各位\n\nお疲れ様です。\n\nイベント資料を作成しましたので、ご確認をお願いします。\n\n ----------------------------------------------------\n#{@site_name}市　企画政策部　広報課\n斎藤　拓也\n電話番号：00−0000−0000\n----------------------------------------------------",
#   to_member_name: "地域振興イベント",
#   member_ids: [u("sys").id, u("admin").id, u("user1").id, u("user3").id, u("user5").id],
#   path: {
#     u("sys").id.to_s => memo_folder(u("sys"), "イベント").id,
#     u("admin").id.to_s => memo_folder(u("admin"), "イベント").id,
#     u("user1").id.to_s => memo_folder(u("user1"), "イベント").id,
#     u("user3").id.to_s => memo_folder(u("user3"), "イベント").id,
#     u("user5").id.to_s => memo_folder(u("user5"), "イベント").id,
#   }
# )

# ##------------------------------------
# puts "# share/file"
#
# def create_file(data)
#   create_item(Gws::Share::File, data)
# end
#
# @sh_files2 = []
# Fs::UploadedFile.create_from_file(Rails.root.join('db/seeds/gws/files/file.pdf'), filename: 'file2.pdf', content_type: 'application/pdf') do |f|
#   @sh_files2 << create_file(in_file: f, name: 'file.pdf', folder_id: @sh_folders[0].id, category_ids: [@sh_cate[3].id])
# end
#
# @sh_folders.each(&:update_folder_descendants_file_info)
#
