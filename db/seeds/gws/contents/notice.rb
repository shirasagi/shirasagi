## -------------------------------------
puts "# notice"

def create_notice_folder(data)
  create_item(Gws::Notice::Folder, data)
end

@nt_folders = [
  create_notice_folder(
    name: "全庁", order: 10, member_group_ids: @groups.map(&:id),
    notice_total_body_size_limit: SS.config.gws.notice["default_notice_total_body_size_limit"],
    notice_individual_file_size_limit: SS.config.gws.notice["default_notice_individual_file_size_limit"],
    notice_total_file_size_limit: SS.config.gws.notice["default_notice_total_file_size_limit"],
    readable_setting_range: 'public'
  )
]

def create_notice_post(data)
  create_item(Gws::Notice::Post, data)
end

create_notice_post(
  name: "#{@site_name}のお知らせです。", text: ("お知らせです。\n" * 4), folder_id: @nt_folders[0].id,
  readable_setting_range: 'public'
)
create_notice_post(
  name: "システムメンテナンスを実施します。", severity: 'high', folder_id: @nt_folders[0].id,
  text: [
    "○月○日○時から○時の間、システムメンテナンスを実施予定です。",
    "詳細は追って連絡しますが、日時に不都合のある方はシステム管理者までご相談ください。 ",
  ].join("\n"),
  readable_setting_range: 'public'
)
