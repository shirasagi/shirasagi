require 'spec_helper'

describe Gws::StaffRecord::UserOccupation, type: :model, dbscope: :example do
  let!(:site1) { create :gws_group }
  let!(:group1) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [ site1.id ] }
  let!(:user2) { create :gws_user, group_ids: [ site1.id ] }
  let!(:year1) { create :gws_staff_record_year, cur_site: site1 }
  let!(:occupation1) do
    create(
      :gws_staff_record_user_occupation, cur_site: site1, year: year1,
      group_ids: [ group1.id, group2.id ], user_ids: [ user1.id, user2.id ], permission_level: rand(1..3)
    )
  end

  let(:encoding) { %w(Shift_JIS UTF-8).sample }
  let(:csv) do
    item = described_class.new
    item.cur_site = site1
    item.year = year1
    item.in_csv_encoding = encoding

    year1.reload
    csv = item.export_csv(year1.yearly_user_occupations.site(site1))
    # clear id to import as new item
    csv = csv.sub("\n#{occupation1.id},", "\n,")
    csv
  end
  let(:csv_as_file) do
    path = tmpfile(extname: ".csv", binary: true) { |f| f.write csv }
    Fs::UploadedFile.create_from_file(path, basename: "spec")
  end

  let!(:site2) { create :gws_group }
  let!(:year2) { create :gws_staff_record_year, cur_site: site2 }

  before do
    admin_role = create(:gws_role_admin, cur_site: site2)
    gws_user.add_to_set(group_ids: site2.id)
    gws_user.add_to_set(gws_role_ids: admin_role.id)

    user1.add_to_set(group_ids: site2.id)
    user2.add_to_set(group_ids: site2.id)
  end

  context "newly import" do
    it do
      item = described_class.new
      item.cur_site = site2
      item.cur_user = gws_user
      item.year = year2
      item.in_file = csv_as_file

      item.import_csv
      expect(item.errors).to be_blank
      expect(Gws::StaffRecord::UserOccupation.all.site(site2).count).to eq 1
      Gws::StaffRecord::UserOccupation.all.site(site2).first.tap do |imported_user_occupation|
        expect(imported_user_occupation.name).to eq occupation1.name
        expect(imported_user_occupation.code).to eq occupation1.code
        expect(imported_user_occupation.remark).to eq occupation1.remark
        expect(imported_user_occupation.order).to eq occupation1.order
        expect(imported_user_occupation.group_ids).to be_blank
        expect(imported_user_occupation.user_ids).to have(3).items
        expect(imported_user_occupation.user_ids).to include(gws_user.id, user1.id, user2.id)
        unless SS.config.ss.disable_permission_level
          expect(imported_user_occupation.permission_level).to eq occupation1.permission_level
        end
      end
    end
  end
end
