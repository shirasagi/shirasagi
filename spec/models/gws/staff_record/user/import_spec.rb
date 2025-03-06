require 'spec_helper'

describe Gws::StaffRecord::User, type: :model, dbscope: :example do
  let!(:site1) { create :gws_group }
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
      readable_member_ids: [user1.id, user2.id], group_ids: [group3.id, group4.id], user_ids: [user3.id, user4.id]
    )
  end

  let(:encoding) { %w(Shift_JIS UTF-8).sample }
  let(:csv) do
    item = described_class.new
    item.cur_site = site1
    item.year = year1
    item.in_csv_encoding = encoding

    year1.reload
    csv = item.export_csv(year1.yearly_users.site(site1))
    # clear id to import as new item
    csv = csv.sub("\n#{staff_record_user1.id},", "\n,")
    csv
  end
  let(:csv_as_file) do
    path = tmpfile(extname: ".csv", binary: true) { |f| f.write csv }
    Fs::UploadedFile.create_from_file(path, basename: "spec")
  end

  let!(:site2) { create :gws_group }
  let!(:year2) { create :gws_staff_record_year, cur_site: site2 }
  let!(:title2) { create :gws_staff_record_user_title, cur_site: site2, year: year2, code: title1.code }
  let!(:occupation2) { create :gws_staff_record_user_occupation, cur_site: site2, year: year2, code: occupation1.code }

  before do
    admin_role = create(:gws_role_admin, cur_site: site2)
    gws_user.add_to_set(group_ids: site2.id)
    gws_user.add_to_set(gws_role_ids: admin_role.id)

    user1.add_to_set(group_ids: site2.id)
    user2.add_to_set(group_ids: site2.id)
    user3.add_to_set(group_ids: site2.id)
    user4.add_to_set(group_ids: site2.id)
  end

  context "newly import" do
    it do
      item = Gws::StaffRecord::User.new
      item.cur_site = site2
      item.cur_user = gws_user
      item.year = year2
      item.in_file = csv_as_file

      item.import_csv
      expect(item.errors).to be_blank
      expect(Gws::StaffRecord::User.all.site(site2).count).to eq 1
      Gws::StaffRecord::User.all.site(site2).first.tap do |imported_user|
        expect(imported_user.name).to eq staff_record_user1.name
        expect(imported_user.code).to eq staff_record_user1.code
        expect(imported_user.order).to eq staff_record_user1.order
        expect(imported_user.kana).to eq staff_record_user1.kana
        expect(imported_user.multi_section).to eq staff_record_user1.multi_section
        expect(imported_user.section_name).to eq staff_record_user1.section_name
        expect(imported_user.title_ids).to have(1).items
        expect(imported_user.titles.first).to eq title2
        expect(imported_user.occupation_ids).to have(1).items
        expect(imported_user.occupations.first).to eq occupation2
        expect(imported_user.tel_ext).to eq staff_record_user1.tel_ext
        expect(imported_user.charge_name).to eq staff_record_user1.charge_name
        expect(imported_user.charge_address).to eq staff_record_user1.charge_address
        expect(imported_user.charge_tel).to eq staff_record_user1.charge_tel
        expect(imported_user.divide_duties).to eq staff_record_user1.divide_duties
        expect(imported_user.remark).to eq staff_record_user1.remark
        expect(imported_user.staff_records_view).to eq staff_record_user1.staff_records_view
        expect(imported_user.divide_duties_view).to eq staff_record_user1.divide_duties_view
        expect(imported_user.readable_setting_range).to eq staff_record_user1.readable_setting_range
        expect(imported_user.readable_group_ids).to be_blank
        expect(imported_user.readable_member_ids).to eq staff_record_user1.readable_member_ids
        expect(imported_user.group_ids).to be_blank
        expect(imported_user.user_ids).to have(3).items
        expect(imported_user.user_ids).to include(gws_user.id, user3.id, user4.id)
      end
    end
  end
end
