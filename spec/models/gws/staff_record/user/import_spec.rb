require 'spec_helper'

describe Gws::StaffRecord::User, type: :model, dbscope: :example do
  let!(:site1) { create :gws_group }
  let!(:year1) { create :gws_staff_record_year, cur_site: site1 }
  let!(:title1) { create :gws_staff_record_user_title, cur_site: site1, year: year1 }
  let!(:user1) { create :gws_staff_record_user, cur_site: site1, year: year1, title_ids: [ title1.id ] }

  let(:encoding) { %w(Shift_JIS UTF-8).sample }
  let(:csv) do
    item = Gws::StaffRecord::User.new
    item.cur_site = site1
    item.year = year1
    item.in_csv_encoding = encoding

    year1.reload
    csv = item.export_csv(year1.yearly_users.site(site1))
    csv = csv.sub("\n#{user1.id},", "\n,")
    csv
  end
  let(:csv_as_file) do
    path = tmpfile(extname: ".csv", binary: true) { |f| f.write csv }
    Fs::UploadedFile.create_from_file(path, basename: "spec")
  end

  let!(:site2) { create :gws_group }
  let!(:year2) { create :gws_staff_record_year, cur_site: site2 }
  let!(:title2) { create :gws_staff_record_user_title, cur_site: site2, year: year2, code: title1.code }

  before do
    admin_role = create(:gws_role_admin, cur_site: site2)
    gws_user.add_to_set(group_ids: site2.id)
    gws_user.add_to_set(gws_role_ids: admin_role.id)
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
        expect(imported_user.name).to eq user1.name
        expect(imported_user.code).to eq user1.code
        expect(imported_user.order).to eq user1.order
        expect(imported_user.kana).to eq user1.kana
        expect(imported_user.multi_section).to eq user1.multi_section
        expect(imported_user.section_name).to eq user1.section_name
        expect(imported_user.title_ids).to have(1).items
        expect(imported_user.titles.first).to eq title2
        expect(imported_user.tel_ext).to eq user1.tel_ext
        expect(imported_user.charge_name).to eq user1.charge_name
        expect(imported_user.charge_address).to eq user1.charge_address
        expect(imported_user.charge_tel).to eq user1.charge_tel
        expect(imported_user.divide_duties).to eq user1.divide_duties
        expect(imported_user.remark).to eq user1.remark
        expect(imported_user.staff_records_view).to eq user1.staff_records_view
        expect(imported_user.divide_duties_view).to eq user1.divide_duties_view
        expect(imported_user.group_ids).to be_blank
        expect(imported_user.user_ids).to eq [ gws_user.id ]
      end
    end
  end
end
