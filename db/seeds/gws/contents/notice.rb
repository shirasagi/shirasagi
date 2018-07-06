## -------------------------------------
puts "# notice"

def create_notice(data)
  create_item(Gws::Notice, data)
end

create_notice name: "#{@site.name}のお知らせです。", text: ("お知らせです。\n" * 4)
create_notice name: "システムメンテナンスを実施します。",
  text: [
    "○月○日○時から○時の間、システムメンテナンスを実施予定です。",
    "詳細は追って連絡しますが、日時に不都合のある方はシステム管理者までご相談ください。 ",
  ].join.("\n"),
  severity: 'high'
