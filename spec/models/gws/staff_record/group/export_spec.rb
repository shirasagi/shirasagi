require 'spec_helper'

describe Gws::StaffRecord::Group, type: :model, dbscope: :example do
  let(:site1) { create :gws_group }
  let!(:group1) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:group2) { create :gws_group, name: "#{site1.name}/#{unique_id}" }
  let!(:user1) { create :gws_user, group_ids: [ site1.id ] }
  let!(:user2) { create :gws_user, group_ids: [ site1.id ] }
  let!(:year1) { create :gws_staff_record_year, cur_site: site1 }
  let!(:staff_record_group1) do
    create(
      :gws_staff_record_group, cur_site: site1, year: year1,
      readable_setting_range: %w(public select private).sample, readable_group_ids: [ group1.id ],
      readable_member_ids: [ user1.id ], group_ids: [ group2.id ], user_ids: [ user2.id ], permission_level: rand(1..3)
    )
  end

  before do
    admin_role = create(:gws_role_admin, cur_site: site1)
    gws_user.add_to_set(group_ids: site1.id)
    gws_user.add_to_set(gws_role_ids: admin_role.id)

    year1.reload
  end

  before do
    @save = SS.config.ss.disable_permission_level
    SS.config.replace_value_at(:ss, :disable_permission_level, [ false, true ].sample)
  end

  after do
    SS.config.replace_value_at(:ss, :disable_permission_level, @save)
  end

  context "with Shift_JIS" do
    let(:encoding) { "Shift_JIS" }

    it do
      item = described_class.new
      item.cur_site = site1
      item.cur_user = gws_user
      item.year = year1
      item.in_csv_encoding = encoding

      csv = item.export_csv(year1.yearly_groups.site(site1))
      csv = csv.encode("UTF-8", "SJIS")
      csv = CSV.parse(csv, headers: true)

      expect(csv.length).to eq 1
      if SS.config.ss.disable_permission_level
        expect(csv.headers.length).to eq 9
      else
        expect(csv.headers.length).to eq 10
      end
      basic_headers = %i[id name seating_chart_url order].map { |f| described_class.t(f) }
      expect(csv.headers).to include(*basic_headers)
      readable_setting_headers = %i[readable_setting_range readable_group_ids readable_member_ids].map do |f|
        described_class.t(f)
      end
      expect(csv.headers).to include(*readable_setting_headers)
      group_permission_header = %i[group_ids user_ids].map { |f| described_class.t(f) }
      expect(csv.headers).to include(*group_permission_header)
      if SS.config.ss.disable_permission_level
        expect(csv.headers).not_to include(*%i[permission_level].map { |f| described_class.t(f) })
      else
        expect(csv.headers).to include(*%i[permission_level].map { |f| described_class.t(f) })
      end
      csv.first.tap do |row|
        if SS.config.ss.disable_permission_level
          expect(row.length).to eq 9
        else
          expect(row.length).to eq 10
        end
        expect(row[described_class.t(:id)]).to eq staff_record_group1.id.to_s
        expect(row[described_class.t(:name)]).to eq staff_record_group1.name
        expect(row[described_class.t(:seating_chart_url)]).to eq staff_record_group1.seating_chart_url
        expect(row[described_class.t(:order)]).to eq staff_record_group1.order.to_s
        expect(row[described_class.t(:readable_setting_range)]).to eq staff_record_group1.label(:readable_setting_range)
        expect(row[described_class.t(:readable_group_ids)]).to eq staff_record_group1.readable_groups.pluck(:name).join("\n")
        expect(row[described_class.t(:readable_member_ids)]).to eq staff_record_group1.readable_members.pluck(:uid).join("\n")
        expect(row[described_class.t(:group_ids)]).to eq staff_record_group1.groups.pluck(:name).join("\n")
        expect(row[described_class.t(:user_ids)]).to eq staff_record_group1.users.pluck(:uid).join("\n")
        unless SS.config.ss.disable_permission_level
          expect(row[described_class.t(:permission_level)]).to eq staff_record_group1.permission_level.to_s
        end
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

      csv = item.export_csv(year1.yearly_groups.site(site1))
      csv = csv.sub(SS::Csv::UTF8_BOM, '')
      csv = CSV.parse(csv, headers: true)

      expect(csv.length).to eq 1
      if SS.config.ss.disable_permission_level
        expect(csv.headers.length).to eq 9
      else
        expect(csv.headers.length).to eq 10
      end
      basic_headers = %i[id name seating_chart_url order].map { |f| described_class.t(f) }
      expect(csv.headers).to include(*basic_headers)
      readable_setting_headers = %i[readable_setting_range readable_group_ids readable_member_ids].map do |f|
        described_class.t(f)
      end
      expect(csv.headers).to include(*readable_setting_headers)
      group_permission_header = %i[group_ids user_ids].map { |f| described_class.t(f) }
      expect(csv.headers).to include(*group_permission_header)
      if SS.config.ss.disable_permission_level
        expect(csv.headers).not_to include(*%i[permission_level].map { |f| described_class.t(f) })
      else
        expect(csv.headers).to include(*%i[permission_level].map { |f| described_class.t(f) })
      end
      csv.first.tap do |row|
        if SS.config.ss.disable_permission_level
          expect(row.length).to eq 9
        else
          expect(row.length).to eq 10
        end
        expect(row[described_class.t(:id)]).to eq staff_record_group1.id.to_s
        expect(row[described_class.t(:name)]).to eq staff_record_group1.name
        expect(row[described_class.t(:seating_chart_url)]).to eq staff_record_group1.seating_chart_url
        expect(row[described_class.t(:order)]).to eq staff_record_group1.order.to_s
        expect(row[described_class.t(:readable_setting_range)]).to eq staff_record_group1.label(:readable_setting_range)
        expect(row[described_class.t(:readable_group_ids)]).to eq staff_record_group1.readable_groups.pluck(:name).join("\n")
        expect(row[described_class.t(:readable_member_ids)]).to eq staff_record_group1.readable_members.pluck(:uid).join("\n")
        expect(row[described_class.t(:group_ids)]).to eq staff_record_group1.groups.pluck(:name).join("\n")
        expect(row[described_class.t(:user_ids)]).to eq staff_record_group1.users.pluck(:uid).join("\n")
        unless SS.config.ss.disable_permission_level
          expect(row[described_class.t(:permission_level)]).to eq staff_record_group1.permission_level.to_s
        end
      end
    end
  end
end
