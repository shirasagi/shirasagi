puts "# share/category"

def create_share_category(data)
  create_item(Gws::Share::Category, data)
end

@sh_cate = [
  create_share_category(name: 'パンフレット', color: '#A600FF', order: 10),
  create_share_category(name: '写真', color: '#0011FF', order: 20),
  create_share_category(name: '申請書', color: '#11FF00', order: 30),
  create_share_category(name: '資料', color: '#FFEE00', order: 40),
]

## -------------------------------------
puts "# share/folder"

def create_share_folder(data)
  create_item(Gws::Share::Folder, data)
end

@sh_folders = [
  create_share_folder(cur_user: u("admin"), name: '講習会資料', order: 10, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("admin"), name: '事業パンフレット', order: 20, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("admin"), name: 'イベント写真', order: 30, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("admin"), name: '座席表', order: 50, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: 'イベント写真/企画セミナー', order: 10, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '事業パンフレット/広報関連パンフレット', order: 10, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '座席表/企画政策部 政策課', order: 10, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '講習会資料/企画セミナー', order: 10, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: 'イベント写真/防災イベント', order: 20, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '事業パンフレット/防災関連パンフレット', order: 20, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '座席表/企画政策部 広報課', order: 20, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '講習会資料/防災セミナー', order: 20, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: 'イベント写真/広報イベント', order: 30, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '事業パンフレット/観光パンフレット', order: 30, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '座席表/危機管理部 管理課', order: 30, group_ids: [g('政策課').id]),
  create_share_folder(cur_user: u("sys"), name: '座席表/危機管理部 防災課', order: 40, group_ids: [g('政策課').id]),
]

def sh_folder(name)
  @sh_folders.find { |folder| folder.name == name || folder.name.end_with?("/#{name}") }
end

## -------------------------------------
puts "# share/file"

def sh_upload_file(path, options = {}, &block)
  path = File.expand_path(path, "#{Rails.root}/db/seeds/gws/files")
  filename = options[:filename] || ::File.basename(path)
  if ::File.extname(filename).blank?
    filename = "#{filename}#{::File.extname(path)}"
  end
  content_type = options[:content_type] || ::Fs.content_type(path)

  Fs::UploadedFile.create_from_file(path, filename: filename, content_type: content_type, &block)
end

def create_share_file(data)
  name = data[:name]
  if ::File.extname(name).blank?
    name = "#{name}#{::File.extname(data[:in_file.filename])}"
    data[:name] = name
  end
  create_item(Gws::Share::File, data)
end

@sh_files = []
sh_upload_file('bosai01.jpg') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: 'bosai01.jpg', folder_id: sh_folder("防災イベント").id,
    category_ids: [@sh_cate[1].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikaku01.jpg') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: 'kikaku01.jpg', folder_id: sh_folder("企画セミナー").id,
    category_ids: [@sh_cate[1].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikaku01.jpg', filename: 'koho01.jpg') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: 'koho01.jpg', folder_id: sh_folder("広報イベント").id,
    category_ids: [@sh_cate[1].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('shirasagi_kohopamphlet.pdf', filename: "#{@site_name}市広報パンフレット.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "#{@site_name}市広報パンフレット.pdf", folder_id: sh_folder("広報関連パンフレット").id,
    category_ids: [@sh_cate[0].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('shirasagi_kohopamphlet.pdf', filename: "#{@site_name}市総合パンフレット.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "#{@site_name}市総合パンフレット.pdf", folder_id: sh_folder("事業パンフレット").id,
    category_ids: [@sh_cate[0].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('shirasagi_kohopamphlet.pdf', filename: "#{@site_name}市観光マップ.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "#{@site_name}市観光マップ.pdf", folder_id: sh_folder("観光パンフレット").id,
    category_ids: [@sh_cate[0].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('shirasagi_kohopamphlet.pdf', filename: "#{@site_name}市観光案内.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "#{@site_name}市観光案内.pdf", folder_id: sh_folder("観光パンフレット").id,
    category_ids: [@sh_cate[0].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('shirasagi_kohopamphlet.pdf', filename: "#{@site_name}市防災計画パンフレット.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "#{@site_name}市防災計画パンフレット.pdf", folder_id: sh_folder("防災関連パンフレット").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('seminar_application.pdf', filename: 'セミナー参加申込書.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: 'セミナー参加申込書.pdf', folder_id: sh_folder("講習会資料").id,
    category_ids: [@sh_cate[2].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('file.pdf', filename: '企画セミナーチラシ.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("admin"), in_file: f, name: '企画セミナーチラシ.pdf', folder_id: sh_folder("講習会資料/企画セミナー").id,
    category_ids: [@sh_cate[3].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikakuseisakubu_kohoka.pdf', filename: '企画政策部広報課.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '企画政策部 広報課.pdf', folder_id: sh_folder("企画政策部 広報課").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikakuseisakubu_seisakuka.pdf', filename: '企画制作部政策課.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("admin"), in_file: f, name: '企画政策部 政策課.pdf', folder_id: sh_folder("企画政策部 政策課").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikikanribu_kanrika.pdf', filename: '危機管理部管理課.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '危機管理部 管理課.pdf', folder_id: sh_folder("危機管理部 管理課").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('kikikanribu_bosaika.pdf', filename: '危機管理部防災課.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '危機管理部 防災課.pdf', folder_id: sh_folder("危機管理部 防災課").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('nenkankousyuukai_keikaku.pdf', filename: '年間講習会計画.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '年間講習会計画.pdf', folder_id: sh_folder("講習会資料").id,
    category_ids: [@sh_cate[3].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('koho_shirasagi.pdf', filename: "広報#{@site_name}.pdf") do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: "広報#{@site_name}.pdf", folder_id: sh_folder("広報関連パンフレット").id,
    category_ids: [@sh_cate[0].id], group_ids: [g('政策課').id]
  )
end
sh_upload_file('hontyousya_floorzu.pdf', filename: '本庁舎フロア図.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '本庁舎フロア図.pdf', folder_id: sh_folder("座席表").id,
    group_ids: [g('政策課').id]
  )
end
sh_upload_file('bosai_seminarreport.pdf', filename: '防災セミナー報告書.pdf') do |f|
  @sh_files << create_share_file(
    cur_user: u("sys"), in_file: f, name: '防災セミナー報告書.pdf', folder_id: sh_folder("防災セミナー").id,
    category_ids: [@sh_cate[3].id], group_ids: [g('政策課').id]
  )
end

# 末端のフォルダーからフォルダー内のサイズをキャッシュしていく。
@sh_folders.sort do |lhs, rhs|
  cmp = lhs.depth <=> rhs.depth
  next cmp if cmp != 0

  cmp = lhs.name <=> rhs.name
  next cmp if cmp != 0

  lhs.id <=> rhs.id
end.reverse_each do |sh|
  sh.reload.update_folder_descendants_file_info
end

def sh_file(name)
  @sh_files.find { |file| file.name == name }
end

## -------------------------------------
# Gws::StaffRecord

load "#{Rails.root}/db/seeds/gws/contents/staff_record.rb"

## -------------------------------------
puts "# shared_address/group"

def create_shared_address_group(data)
  create_item(Gws::SharedAddress::Group, data)
end

@sh_address_group = [

  create_shared_address_group(name: '企画政策部 政策課', order: 10),
  create_shared_address_group(name: '企画政策部 広報課', order: 10),
  create_shared_address_group(name: '危機管理部 管理課', order: 10),
  create_shared_address_group(name: '危機管理部 防災課', order: 10),
]

## -------------------------------------
puts "# shared_address/address"

def create_shared_address_address(data)
  create_item(Gws::SharedAddress::Address, data)
end

create_shared_address_address(
  name: 'サイト管理者', member_id: u('admin'), email: 'admin@demo-ss-proj.org', kana: 'サイト カンリシャ',
  readable_setting_range: 'public', address_group_id: @sh_address_group[1].id
)
create_shared_address_address(
  name: 'システム管理者', member_id: u('sys').id, email: 'sys@demo-ss-proj.org',
  address_group_id: @sh_address_group[1].id
)
create_shared_address_address(
  name: '伊藤 幸子', member_id: u('user4').id, email: 'user4@demo-ss.proj.org',
  address_group_id: @sh_address_group[3].id
)
create_shared_address_address(
  name: '斉藤 拓也', member_id: u('user3').id, email: 'user3@demo-ss.proj.org',
  address_group_id: @sh_address_group[2].id
)
create_shared_address_address(
  name: '渡辺 和子', member_id: u('user2').id, email: 'user2@demo-ss.proj.org',
  address_group_id: @sh_address_group[3].id
)
create_shared_address_address(
  name: '鈴木 茂', member_id: u('user1').id, email: 'user1@demo-ss.proj.org',
  address_group_id: @sh_address_group[1].id
)
create_shared_address_address(
  name: '高橋 清', member_id: u('user5').id, email: 'user5@demo-ss.prpj.org',
  address_group_id: @sh_address_group[2].id
)
