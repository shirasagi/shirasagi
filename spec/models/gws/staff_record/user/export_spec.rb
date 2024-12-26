require 'spec_helper'

describe Gws::StaffRecord::User, type: :model, dbscope: :example do
  let(:site1) { create :gws_group }
  let!(:group1) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:group3) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:group4) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [ site1.id ] }
  let!(:user2) { create :gws_user, group_ids: [ site1.id ] }
  let!(:user3) { create :gws_user, group_ids: [ site1.id ] }
  let!(:user4) { create :gws_user, group_ids: [ site1.id ] }
  let!(:year1) { create :gws_staff_record_year, cur_site: site1 }
  let!(:title1) { create :gws_staff_record_user_title, cur_site: site1, year: year1 }
  let!(:occupation1) { create :gws_staff_record_user_occupation, cur_site: site1, year: year1 }
  # let(:readable_setting_range) { %w(public select private).sample }
  let(:readable_setting_range) { "select" }
  let!(:staff_record_user1) do
    create(
      :gws_staff_record_user, cur_site: site1, year: year1, title_ids: [title1.id], occupation_ids: [occupation1.id],
      readable_setting_range: readable_setting_range, readable_group_ids: [group1.id, group2.id],
      readable_member_ids: [user1.id, user2.id], group_ids: [group3.id, group4.id], user_ids: [user3.id, user4.id],
      permission_level: rand(1..3)
    )
  end

  before do
    admin_role = create(:gws_role_admin, cur_site: site1)
    gws_user.add_to_set(group_ids: site1.id)
    gws_user.add_to_set(gws_role_ids: admin_role.id)

    year1.reload
  end

  context "with Shift_JIS" do
    let(:encoding) { "Shift_JIS" }

    it do
      item = described_class.new
      item.cur_site = site1
      item.cur_user = gws_user
      item.year = year1
      item.in_csv_encoding = encoding

      csv = item.export_csv(year1.yearly_users.site(site1))
      csv = csv.encode("UTF-8", "SJIS")
      csv = CSV.parse(csv, headers: true)

      expect(csv.length).to eq 1
      expect(csv.headers.length).to eq 22
      expect(csv.headers).to include(*%i[id name code order kana].map { |f| described_class.t(f) })
      expect(csv.headers).not_to include(*%i[section_order permission_level].map { |f| described_class.t(f) })
      csv.first.tap do |row|
        expect(row.length).to eq 22
        expect(row[described_class.t(:id)]).to eq staff_record_user1.id.to_s
        expect(row[described_class.t(:name)]).to eq staff_record_user1.name
        expect(row[described_class.t(:code)]).to eq staff_record_user1.code
        expect(row[described_class.t(:order)]).to eq staff_record_user1.order.to_s
        expect(row[described_class.t(:kana)]).to eq staff_record_user1.kana
        expect(row[described_class.t(:multi_section)]).to eq staff_record_user1.label(:multi_section)
        expect(row[described_class.t(:section_name)]).to eq staff_record_user1.section_name
        expect(row[described_class.t(:title_ids)]).to eq title1.code
        expect(row[described_class.t(:occupation_ids)]).to eq occupation1.code
        expect(row[described_class.t(:tel_ext)]).to eq staff_record_user1.tel_ext
        expect(row[described_class.t(:charge_name)]).to eq staff_record_user1.charge_name
        expect(row[described_class.t(:charge_address)]).to eq staff_record_user1.charge_address
        expect(row[described_class.t(:charge_tel)]).to eq staff_record_user1.charge_tel
        expect(row[described_class.t(:divide_duties)]).to eq staff_record_user1.divide_duties
        expect(row[described_class.t(:remark)]).to eq staff_record_user1.remark
        expect(row[described_class.t(:staff_records_view)]).to eq staff_record_user1.label(:staff_records_view)
        expect(row[described_class.t(:divide_duties_view)]).to eq staff_record_user1.label(:divide_duties_view)
        expect(row[described_class.t(:readable_setting_range)]).to eq staff_record_user1.label(:readable_setting_range)
        expect(row[described_class.t(:readable_group_ids)]).to eq staff_record_user1.readable_groups.pluck(:name).join("\n")
        expect(row[described_class.t(:readable_member_ids)]).to eq staff_record_user1.readable_members.pluck(:uid).join("\n")
        expect(row[described_class.t(:group_ids)]).to eq staff_record_user1.groups.pluck(:name).join("\n")
        expect(row[described_class.t(:user_ids)]).to eq staff_record_user1.users.pluck(:uid).join("\n")
      end
    end
  end

  context "with UTF-8" do
    let(:encoding) { "UTF-8" }

    it do
      item = described_class.new
      item.cur_site = site1
      item.cur_user = gws_user
      item.year = year1
      item.in_csv_encoding = encoding

      csv = item.export_csv(year1.yearly_users.site(site1))
      csv = csv.sub(SS::Csv::UTF8_BOM, '')
      csv = CSV.parse(csv, headers: true)

      expect(csv.length).to eq 1
      expect(csv.headers.length).to eq 22
      expect(csv.headers).to include(*%i[id name code order kana].map { |f| described_class.t(f) })
      expect(csv.headers).not_to include(*%i[section_order permission_level].map { |f| described_class.t(f) })
      csv.first.tap do |row|
        expect(row.length).to eq 22
        expect(row[described_class.t(:id)]).to eq staff_record_user1.id.to_s
        expect(row[described_class.t(:name)]).to eq staff_record_user1.name
        expect(row[described_class.t(:code)]).to eq staff_record_user1.code
        expect(row[described_class.t(:order)]).to eq staff_record_user1.order.to_s
        expect(row[described_class.t(:kana)]).to eq staff_record_user1.kana
        expect(row[described_class.t(:multi_section)]).to eq staff_record_user1.label(:multi_section)
        expect(row[described_class.t(:section_name)]).to eq staff_record_user1.section_name
        expect(row[described_class.t(:title_ids)]).to eq title1.code
        expect(row[described_class.t(:occupation_ids)]).to eq occupation1.code
        expect(row[described_class.t(:tel_ext)]).to eq staff_record_user1.tel_ext
        expect(row[described_class.t(:charge_name)]).to eq staff_record_user1.charge_name
        expect(row[described_class.t(:charge_address)]).to eq staff_record_user1.charge_address
        expect(row[described_class.t(:charge_tel)]).to eq staff_record_user1.charge_tel
        expect(row[described_class.t(:divide_duties)]).to eq staff_record_user1.divide_duties
        expect(row[described_class.t(:remark)]).to eq staff_record_user1.remark
        expect(row[described_class.t(:staff_records_view)]).to eq staff_record_user1.label(:staff_records_view)
        expect(row[described_class.t(:divide_duties_view)]).to eq staff_record_user1.label(:divide_duties_view)
        expect(row[described_class.t(:readable_setting_range)]).to eq staff_record_user1.label(:readable_setting_range)
        expect(row[described_class.t(:readable_group_ids)]).to eq staff_record_user1.readable_groups.pluck(:name).join("\n")
        expect(row[described_class.t(:readable_member_ids)]).to eq staff_record_user1.readable_members.pluck(:uid).join("\n")
        expect(row[described_class.t(:group_ids)]).to eq staff_record_user1.groups.pluck(:name).join("\n")
        expect(row[described_class.t(:user_ids)]).to eq staff_record_user1.users.pluck(:uid).join("\n")
      end
    end
  end
end
