# --------------------------------------
# Seed
def save_member(data)
  puts data[:email]
  cond = { site_id: @site._id, email: data[:email] }

  item = Cms::Member.find_or_create_by(cond)
  item.attributes = data
  item.update
  item
end

@member_1 = save_member(
  email: "member@example.jp",
  in_password: "pass123",
  state: "enabled",
  name: "白鷺　太郎",
  kana: "しらさぎ　たろう",
  job: "シラサギ株式会社",
  postal_code: "1050001",
  addr: "東京都港区虎ノ門1-1-1",
  sex: "male",
  birthday: Date.parse("1988/10/10")
)
@member_2 = save_member(
  email: "shirasagi_hanako@example.jp",
  in_password: "pass123",
  state: "enabled",
  name: "白鷺　花子",
  kana: "しらさぎ　はなこ",
  postal_code: "1050001",
  addr: "東京都港区虎ノ門1-1-1",
  sex: "female",
  birthday: Date.parse("1990/07/07")
)
member_group = Member::Group.create cur_site: @site, name: "白鷺家",
  invitation_message: "白鷺家のグループです。", in_admin_member_ids: [ @member_1.id ]
member_group.members.new(member_id: @member_2.id, state: "user")
member_group.save
