puts 'ss/users.rb'
site_name = SS::Db::Seed.site_name || 'シラサギ市'

# --------------------------------------
# Users Seed

def save_group(data)
  if item = SS::Group.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update! data
    return item
  end

  puts "create #{data[:name]}"
  item = SS::Group.new(data)
  item.save
  item
end

puts "# groups"
g000 = save_group name: site_name, order: 10
g100 = save_group name: "#{site_name}/企画政策部", order: 20
g110 = save_group name: "#{site_name}/企画政策部/政策課", order: 30
g111 = save_group name: "#{site_name}/企画政策部/政策課/経営戦略係", order: 40
g112 = save_group name: "#{site_name}/企画政策部/政策課/デジタル戦略係", order: 50
g120 = save_group name: "#{site_name}/企画政策部/広報課", order: 60
g200 = save_group name: "#{site_name}/危機管理部", order: 70
g210 = save_group name: "#{site_name}/危機管理部/管理課", order: 80
g220 = save_group name: "#{site_name}/危機管理部/防災課", order: 90
g221 = save_group name: "#{site_name}/危機管理部/防災課/生活安全係", order: 100
g222 = save_group name: "#{site_name}/危機管理部/防災課/消防団係", order: 110
g300 = save_group name: "#{site_name}/総務部", order: 120
g310 = save_group name: "#{site_name}/総務部/人事課", order: 130
g311 = save_group name: "#{site_name}/総務部/人事課/人材育成係", order: 140
g320 = save_group name: "#{site_name}/総務部/財産管理課", order: 150
g321 = save_group name: "#{site_name}/総務部/財産管理課/管理・営繕係", order: 160
g322 = save_group name: "#{site_name}/総務部/財産管理課/電算管理係", order: 180
g330 = save_group name: "#{site_name}/総務部/市民課", order: 190
g331 = save_group name: "#{site_name}/総務部/市民課/市民税係", order: 200
g332 = save_group name: "#{site_name}/総務部/市民課/戸籍係", order: 210
g400 = save_group name: "#{site_name}/福祉健康部", order: 220
g410 = save_group name: "#{site_name}/福祉健康部/社会福祉課", order: 230
g411 = save_group name: "#{site_name}/福祉健康部/社会福祉課/福祉政策係", order: 240
g412 = save_group name: "#{site_name}/福祉健康部/社会福祉課/障がい福祉係", order: 250
g420 = save_group name: "#{site_name}/福祉健康部/子育て支援課", order: 260

# contact
g110.cms_group.tap do |cms_g110|
  if cms_g110.contact_groups.blank?
    cms_g110.contact_groups.create(
      main_state: "main", name: "企画政策部 政策課", contact_group_name: "企画政策部 政策課",
      contact_tel: "000-000-0000", contact_fax: "000-000-0001", contact_email: "kikakuseisaku@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号', contact_link_url: "/kikaku/seisaku/",
      contact_link_name: "企画政策部 政策課")
    cms_g110.contact_group_name = "企画政策部 政策課"
    cms_g110.contact_tel = "000-000-0000"
    cms_g110.contact_fax = "000-000-0001"
    cms_g110.contact_email = "kikakuseisaku@example.jp"
    cms_g110.contact_postal_code = '0000000'
    cms_g110.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g110.contact_link_url = "/kikaku/seisaku/"
    cms_g110.contact_link_name = "企画政策部 政策課"
    cms_g110.save
  end
end
g111.cms_group.tap do |cms_g111|
  if cms_g111.contact_groups.blank?
    cms_g111.contact_groups.create(
      main_state: "main", name: "企画政策部 政策課 経営戦略係", contact_group_name: "企画政策部 政策課", contact_charge: "経営戦略係",
      contact_tel: "000-000-0000", contact_fax: "000-000-0001", contact_email: "kikakuseisaku@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g111.contact_group_name = "企画政策部 政策課"
    cms_g111.contact_charge = "経営戦略係"
    cms_g111.contact_tel = "000-000-0000"
    cms_g111.contact_fax = "000-000-0001"
    cms_g111.contact_email = "kikakuseisaku@example.jp"
    cms_g111.contact_postal_code = '0000000'
    cms_g111.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g111.save
  end
end
g112.cms_group.tap do |cms_g112|
  if cms_g112.contact_groups.blank?
    cms_g112.contact_groups.create(
      main_state: "main", name: "企画政策部 政策課 デジタル戦略係", contact_group_name: "企画政策部 政策課", contact_charge: "デジタル戦略係",
      contact_tel: "000-000-0000", contact_fax: "000-000-0001", contact_email: "kikakuseisaku@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g112.contact_group_name = "企画政策部 政策課"
    cms_g112.contact_charge = "デジタル戦略係"
    cms_g112.contact_tel = "000-000-0000"
    cms_g112.contact_fax = "000-000-0001"
    cms_g112.contact_email = "kikakuseisaku@example.jp"
    cms_g112.contact_postal_code = '0000000'
    cms_g112.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g112.save
  end
end
g120.cms_group.tap do |cms_g120|
  if cms_g120.contact_groups.blank?
    cms_g120.contact_groups.create(
      main_state: "main", name: "企画政策部 広報課", contact_group_name: "企画政策部 広報課",
      contact_tel: "111-111-1111", contact_fax: "111-111-1112", contact_email: "koho@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g120.contact_group_name = "企画政策部 広報課"
    cms_g120.contact_tel = "111-111-1111"
    cms_g120.contact_fax = "111-111-1112"
    cms_g120.contact_email = "koho@example.jp"
    cms_g120.contact_postal_code = '0000000'
    cms_g120.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g120.save
  end
end
g210.cms_group.tap do |cms_g210|
  if cms_g210.contact_groups.blank?
    cms_g210.contact_groups.create(
      main_state: "main", name: "危機管理部 管理課", contact_group_name: "危機管理部 管理課",
      contact_tel: "222-2222-2222", contact_fax: "222-2222-2223", contact_email: "kikikanri_kanri@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g210.contact_group_name = "危機管理部 管理課"
    cms_g210.contact_tel = "222-2222-2222"
    cms_g210.contact_fax = "222-2222-2223"
    cms_g210.contact_email = "kikikanri_kanri@example.jp"
    cms_g210.contact_postal_code = '0000000'
    cms_g210.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g210.save
  end
end
g220.cms_group.tap do |cms_g220|
  if cms_g220.contact_groups.blank?
    cms_g220.contact_groups.create(
      main_state: "main", name: "危機管理部 防災課", contact_group_name: "危機管理部 防災課",
      contact_tel: "333-3333-3333", contact_fax: "333-3333-3334", contact_email: "kikikanri_bousai@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g220.contact_group_name = "危機管理部 防災課"
    cms_g220.contact_tel = "333-3333-3333"
    cms_g220.contact_fax = "333-3333-3334"
    cms_g220.contact_email = "kikikanri_bousai@example.jp"
    cms_g220.contact_postal_code = '0000000'
    cms_g220.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g220.save
  end
end
g221.cms_group.tap do |cms_g221|
  if cms_g221.contact_groups.blank?
    cms_g221.contact_groups.create(
      main_state: "main", name: "危機管理部 防災課 生活安全係", contact_group_name: "危機管理部 防災課", contact_charge: "生活安全係",
      contact_tel: "333-3333-3333", contact_fax: "333-3333-3334", contact_email: "kikikanri_bousai@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g221.contact_group_name = "危機管理部 防災課"
    cms_g221.contact_charge = "生活安全係"
    cms_g221.contact_tel = "333-3333-3333"
    cms_g221.contact_fax = "333-3333-3334"
    cms_g221.contact_email = "kikikanri_bousai@example.jp"
    cms_g221.contact_postal_code = '0000000'
    cms_g221.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g221.save
  end
end
g222.cms_group.tap do |cms_g222|
  if cms_g222.contact_groups.blank?
    cms_g222.contact_groups.create(
      main_state: "main", name: "危機管理部 防災課 消防団係", contact_group_name: "危機管理部 防災課", contact_charge: "消防団係",
      contact_tel: "333-3333-3333", contact_fax: "333-3333-3334", contact_email: "kikikanri_bousai@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g222.contact_group_name = "危機管理部 防災課"
    cms_g222.contact_charge = "消防団係"
    cms_g222.contact_tel = "333-3333-3333"
    cms_g222.contact_fax = "333-3333-3334"
    cms_g222.contact_email = "kikikanri_bousai@example.jp"
    cms_g222.contact_postal_code = '0000000'
    cms_g222.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g222.save
  end
end
g310.cms_group.tap do |cms_g310|
  if cms_g310.contact_groups.blank?
    cms_g310.contact_groups.create(
      main_state: "main", name: "総務部 人事課", contact_group_name: "総務部 人事課",
      contact_tel: "444-4444-4444", contact_fax: "444-4444-4445", contact_email: "jinji@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g310.contact_group_name = "総務部 人事課"
    cms_g310.contact_tel = "444-4444-4444"
    cms_g310.contact_fax = "444-4444-4445"
    cms_g310.contact_email = "jinji@example.jp"
    cms_g310.contact_postal_code = '0000000'
    cms_g310.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g310.save
  end
end
g311.cms_group.tap do |cms_g311|
  if cms_g311.contact_groups.blank?
    cms_g311.contact_groups.create(
      main_state: "main", name: "総務部 人事課 人材育成係", contact_group_name: "総務部 人事課", contact_charge: "人材育成係",
      contact_tel: "444-4444-4444", contact_fax: "444-4444-4445", contact_email: "jinji@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g311.contact_group_name = "総務部 人事課"
    cms_g311.contact_charge = "人材育成係"
    cms_g311.contact_tel = "444-4444-4444"
    cms_g311.contact_fax = "444-4444-4445"
    cms_g311.contact_email = "jinji@example.jp"
    cms_g311.contact_postal_code = '0000000'
    cms_g311.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g311.save
  end
end
g320.cms_group.tap do |cms_g320|
  if cms_g320.contact_groups.blank?
    cms_g320.contact_groups.create(
      main_state: "main", name: "総務部 財産管理課", contact_group_name: "総務部 財産管理課",
      contact_tel: "555-555-5555", contact_fax: "555-555-5556", contact_email: "zaisankanri@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g320.contact_group_name = "総務部 財産管理課"
    cms_g320.contact_tel = "555-555-5555"
    cms_g320.contact_fax = "555-555-5556"
    cms_g320.contact_email = "zaisankanri@example.jp"
    cms_g320.contact_postal_code = '0000000'
    cms_g320.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g320.save
  end
end
g321.cms_group.tap do |cms_g321|
  if cms_g321.contact_groups.blank?
    cms_g321.contact_groups.create(
      main_state: "main", name: "総務部 財産管理課 管理・営繕係", contact_group_name: "総務部 財産管理課", contact_charge: "管理・営繕係",
      contact_tel: "555-555-5555", contact_fax: "555-555-5556", contact_email: "zaisankanri@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g321.contact_group_name = "総務部 財産管理課"
    cms_g321.contact_charge = "管理・営繕係"
    cms_g321.contact_tel = "555-555-5555"
    cms_g321.contact_fax = "555-555-5556"
    cms_g321.contact_email = "zaisankanri@example.jp"
    cms_g321.contact_postal_code = '0000000'
    cms_g321.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g321.save
  end
end
g322.cms_group.tap do |cms_g322|
  if cms_g322.contact_groups.blank?
    cms_g322.contact_groups.create(
      main_state: "main", name: "総務部 財産管理課 電算管理係", contact_group_name: "総務部 財産管理課", contact_charge: "電算管理係",
      contact_tel: "555-555-5555", contact_fax: "555-555-5556", contact_email: "zaisankanri@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g322.contact_group_name = "総務部 財産管理課"
    cms_g322.contact_charge = "電算管理係"
    cms_g322.contact_tel = "555-555-5555"
    cms_g322.contact_fax = "555-555-5556"
    cms_g322.contact_email = "zaisankanri@example.jp"
    cms_g322.contact_postal_code = '0000000'
    cms_g322.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g322.save
  end
end
g330.cms_group.tap do |cms_g330|
  if cms_g330.contact_groups.blank?
    cms_g330.contact_groups.create(
      main_state: "main", name: "総務部 市民課", contact_group_name: "総務部 市民課",
      contact_tel: "666-666-6666", contact_fax: "666-666-6667", contact_email: "shimin@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g330.contact_group_name = "総務部 市民課"
    cms_g330.contact_tel = "666-666-6666"
    cms_g330.contact_fax = "666-666-6667"
    cms_g330.contact_email = "shimin@example.jp"
    cms_g330.contact_postal_code = '0000000'
    cms_g330.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g330.save
  end
end
g331.cms_group.tap do |cms_g331|
  if cms_g331.contact_groups.blank?
    cms_g331.contact_groups.create(
      main_state: "main", name: "総務部 市民課 市民税係", contact_group_name: "総務部 市民課", contact_charge: "市民税係",
      contact_tel: "666-666-6666", contact_fax: "666-666-6667", contact_email: "shimin@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g331.contact_group_name = "総務部 市民課"
    cms_g331.contact_charge = "市民税係"
    cms_g331.contact_tel = "666-666-6666"
    cms_g331.contact_fax = "666-666-6667"
    cms_g331.contact_email = "shimin@example.jp"
    cms_g331.contact_postal_code = '0000000'
    cms_g331.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g331.save
  end
end
g332.cms_group.tap do |cms_g332|
  if cms_g332.contact_groups.blank?
    cms_g332.contact_groups.create(
      main_state: "main", name: "総務部 市民課 戸籍係", contact_group_name: "総務部 市民課", contact_charge: "戸籍係",
      contact_tel: "666-666-6666", contact_fax: "666-666-6667", contact_email: "shimin@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g332.contact_group_name = "総務部 市民課"
    cms_g332.contact_charge = "戸籍係"
    cms_g332.contact_tel = "666-666-6666"
    cms_g332.contact_fax = "666-666-6667"
    cms_g332.contact_email = "shimin@example.jp"
    cms_g332.contact_postal_code = '0000000'
    cms_g332.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g332.save
  end
end
g410.cms_group.tap do |cms_g410|
  if cms_g410.contact_groups.blank?
    cms_g410.contact_groups.create(
      main_state: "main", name: "福祉健康部 社会福祉課", contact_group_name: "福祉健康部 社会福祉課",
      contact_tel: "777-777-7777", contact_fax: "777-777-7778", contact_email: "fukushi@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g410.contact_group_name = "福祉健康部 社会福祉課"
    cms_g410.contact_tel = "777-777-7777"
    cms_g410.contact_fax = "777-777-7778"
    cms_g410.contact_email = "fukushi@example.jp"
    cms_g410.contact_postal_code = '0000000'
    cms_g410.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g410.save
  end
end
g411.cms_group.tap do |cms_g411|
  if cms_g411.contact_groups.blank?
    cms_g411.contact_groups.create(
      main_state: "main", name: "福祉健康部 社会福祉課 福祉政策係", contact_group_name: "福祉健康部 社会福祉課", contact_charge: "福祉政策係",
      contact_tel: "777-777-7777", contact_fax: "777-777-7778", contact_email: "fukushi@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g411.contact_group_name = "福祉健康部 社会福祉課"
    cms_g411.contact_charge = "福祉政策係"
    cms_g411.contact_tel = "777-777-7777"
    cms_g411.contact_fax = "777-777-7778"
    cms_g411.contact_email = "fukushi@example.jp"
    cms_g411.contact_postal_code = '0000000'
    cms_g411.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g411.save
  end
end
g412.cms_group.tap do |cms_g412|
  if cms_g412.contact_groups.blank?
    cms_g412.contact_groups.create(
      main_state: "main", name: "福祉健康部 社会福祉課 障がい福祉係", contact_group_name: "福祉健康部 社会福祉課", contact_charge: "障がい福祉係",
      contact_tel: "777-777-7777", contact_fax: "777-777-7778", contact_email: "fukushi@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g412.contact_group_name = "福祉健康部 社会福祉課"
    cms_g412.contact_charge = "障がい福祉係"
    cms_g412.contact_tel = "777-777-7777"
    cms_g412.contact_fax = "777-777-7778"
    cms_g412.contact_email = "fukushi@example.jp"
    cms_g412.contact_postal_code = '0000000'
    cms_g412.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g412.save
  end
end
g420.cms_group.tap do |cms_g420|
  if cms_g420.contact_groups.blank?
    cms_g420.contact_groups.create(
      main_state: "main", name: "福祉健康部 子育て支援課", contact_group_name: "福祉健康部 子育て支援課",
      contact_tel: "888-888-8888", contact_fax: "888-888-8889", contact_email: "kosodate@example.jp", contact_postal_code: '0000000',
      contact_address: '大鷺県シラサギ市小鷺町1丁目1番地1号')
    cms_g420.contact_group_name = "福祉健康部 社会福祉課"
    cms_g420.contact_tel = "888-888-8888"
    cms_g420.contact_fax = "888-888-8889"
    cms_g420.contact_email = "kosodate@example.jp"
    cms_g420.contact_postal_code = '0000000'
    cms_g420.contact_address = '大鷺県シラサギ市小鷺町1丁目1番地1号'
    cms_g420.save
  end
end

# lsorg
g111.overview = "総合計画の策定及び進行管理に関すること\n重要政策の企画、立案及び総合調整"
g111.save
g112.overview = "情報システムの標準化に係る支援\nマイナンバー制度\nオープンデータ推進"
g112.save
g120.overview = "市政に関する情報提供、広報紙の発行"
g120.save
g210.overview = "大規模災害\nテロや有事などの国民保護事案\n新型コロナウイルスなどの感染症"
g210.save
g221.overview = "災害などの防災体制の充実\n調布市消防団の活動支援を行い消防力の強化"
g221.save
g222.overview = "災害対策基本法の施行関連\n市町村の防災対策の指導"
g222.save

def save_role(data)
  if item = Sys::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Sys::Role.new(data)
  puts item.errors.full_messages unless item.save
  item
end

puts "# roles"
sys_r01 = save_role name: I18n.t('sys.roles.admin'), permissions: Sys::Role.permission_names
sys_r02 = save_role name: I18n.t('sys.roles.user'), permissions: %w(use_cms use_gws use_webmail)

def save_user(data, only_on_creates = {})
  if item = SS::User.where(uid: data[:uid]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  SS::User.find_or_create_by!(email: data[:email]) do |item|
    item.attributes = data.merge(only_on_creates)
  end
end

puts "# users"
sys = save_user(
  { name: "システム管理者", uid: "sys", email: "sys@example.jp", in_password: "pass", kana: "システムカンリシャ" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g110.id], sys_role_ids: [sys_r01.id],
    organization_id: g000.id, organization_uid: "0000001", deletion_lock_state: "locked" }
)
adm = save_user(
  { name: "サイト管理者", uid: "admin", email: "admin@example.jp", in_password: "pass", kana: "サイトカンリシャ " },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g110.id], sys_role_ids: [sys_r02.id],
    organization_id: g000.id, organization_uid: "0000000", deletion_lock_state: "locked" }
)
u01 = save_user(
  { name: "鈴木 茂", uid: "user1", email: "user1@example.jp", in_password: "pass", kana: "スズキ シゲル" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g110.id], sys_role_ids: [sys_r02.id],
    organization_id: g000.id, organization_uid: "0000002" }
)
u02 = save_user(
  { name: "渡辺 和子", uid: "user2", email: "user2@example.jp", in_password: "pass", kana: "ワタナベ カズコ" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g210.id], sys_role_ids: [sys_r02.id],
    organization_id: g000.id, organization_uid: "0000003" }
)
u03 = save_user(
  { name: "斎藤　拓也", uid: "user3", email: "user3@example.jp", in_password: "pass", kana: "サイトウ　タクヤ" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g120.id, g220.id], sys_role_ids: [sys_r02.id], organization_id: g000.id, organization_uid: "0000005" }
)
u04 = save_user(
  { name: "伊藤 幸子", uid: "user4", email: "user4@example.jp", in_password: "pass", kana: "イトウ サチコ" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g210.id], sys_role_ids: [sys_r02.id],
    organization_id: g000.id, organization_uid: "0000006" }
)
u05 = save_user(
  { name: "高橋 清", uid: "user5", email: "user5@example.jp", in_password: "pass", kana: "タカハシ キヨシ" },
  {
    type: SS::User::TYPE_SNS,
    group_ids: [g120.id], sys_role_ids: [sys_r02.id],
    organization_id: g000.id, organization_uid: "0000007" }
)

sys.add_to_set(group_ids: [g110.id], sys_role_ids: [sys_r01.id])
adm.add_to_set(group_ids: [g110.id], sys_role_ids: [sys_r02.id])
u01.add_to_set(group_ids: [g110.id], sys_role_ids: [sys_r02.id])
u02.add_to_set(group_ids: [g210.id], sys_role_ids: [sys_r02.id])
u03.add_to_set(group_ids: [g120.id, g220.id], sys_role_ids: [sys_r02.id])
u04.add_to_set(group_ids: [g210.id], sys_role_ids: [sys_r02.id])
u05.add_to_set(group_ids: [g120.id], sys_role_ids: [sys_r02.id])

## -------------------------------------
# Gws Roles

def save_gws_role(data)
  if item = Gws::Role.where(site_id: data[:site_id], name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Gws::Role.new(data)
  item.save
  item
end

def load_gws_permissions(path)
  File.read("#{Rails.root}/db/seeds/#{path}").split(/\r?\n/).map(&:strip) & Gws::Role.permission_names
end

puts "# gws roles"
gws_r01 = save_gws_role name: I18n.t('gws.roles.admin'), site_id: g000.id,
  permissions: Gws::Role.permission_names, permission_level: 3
gws_r02 = save_gws_role name: I18n.t('gws.roles.user'), site_id: g000.id,
  permissions: load_gws_permissions('gws/roles/user_permissions.txt'), permission_level: 1
gws_r03 = save_gws_role name: '部課長', site_id: g000.id,
  permissions: load_gws_permissions('gws/roles/manager_permissions.txt'), permission_level: 1

Gws::User.find_by(uid: "sys").add_to_set(gws_role_ids: gws_r01.id)
Gws::User.find_by(uid: "admin").add_to_set(gws_role_ids: gws_r01.id)
Gws::User.find_by(uid: "user1").add_to_set(gws_role_ids: gws_r02.id)
Gws::User.find_by(uid: "user2").add_to_set(gws_role_ids: gws_r02.id)
Gws::User.find_by(uid: "user3").add_to_set(gws_role_ids: gws_r03.id)
Gws::User.find_by(uid: "user4").add_to_set(gws_role_ids: gws_r03.id)
Gws::User.find_by(uid: "user5").add_to_set(gws_role_ids: gws_r02.id)

## -------------------------------------
# Webmail Roles

def save_webmail_role(data)
  if item = Webmail::Role.where(name: data[:name]).first
    puts "exists #{data[:name]}"
    item.update data
    return item
  end

  puts "create #{data[:name]}"
  item = Webmail::Role.new(data)
  item.save
  item
end

def load_webmail_permissions(path)
  File.read("#{Rails.root}/db/seeds/#{path}").split(/\r?\n/).map(&:strip) & Webmail::Role.permission_names
end

puts "# webmail roles"
webmail_r01 = save_webmail_role(
  name: I18n.t('webmail.roles.admin'), permissions: Webmail::Role.permission_names, permission_level: 3
)
webmail_r02 = save_webmail_role(
  name: I18n.t('webmail.roles.user'), permissions: load_webmail_permissions('webmail/roles/user_permissions.txt'),
  permission_level: 1
)

Webmail::User.find_by(uid: "sys").add_to_set(webmail_role_ids: webmail_r01.id)
Webmail::User.find_by(uid: "admin").add_to_set(webmail_role_ids: webmail_r01.id)
Webmail::User.find_by(uid: "user1").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user2").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user3").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user4").add_to_set(webmail_role_ids: webmail_r02.id)
Webmail::User.find_by(uid: "user5").add_to_set(webmail_role_ids: webmail_r02.id)
