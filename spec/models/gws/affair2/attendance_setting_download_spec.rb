require 'spec_helper'

describe Gws::Affair2::AttendanceSettingDownloader, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let!(:attendance_u1) { affair2.attendance_settings.u1 }
  let!(:attendance_u2) { affair2.attendance_settings.u2 }
  let!(:attendance_u3) { affair2.attendance_settings.u3 }
  let!(:attendance_u4) { affair2.attendance_settings.u4 }
  let!(:attendance_u5) { affair2.attendance_settings.u5 }
  let!(:attendance_u6) { affair2.attendance_settings.u6 }
  let!(:attendance_u7) { affair2.attendance_settings.u7 }
  let!(:attendance_u8) { affair2.attendance_settings.u8 }
  let!(:attendance_u9) { affair2.attendance_settings.u9 }
  let!(:attendance_u10) { affair2.attendance_settings.u10 }
  let!(:attendance_u11) { affair2.attendance_settings.u11 }
  let!(:attendance_u12) { affair2.attendance_settings.u12 }

  let(:all_csv) do
    downloader = described_class.new(site)
    enumerable = downloader.all_enum_csv(encoding: "UTF-8")
    CSV.parse(enumerable.to_a.join, headers: true)
  end

  it do
    expect(all_csv.length).to eq 12
    expect(all_csv[0][1]).to eq "#{attendance_u1.user_id},#{attendance_u1.user.name}"
    expect(all_csv[0][2]).to eq attendance_u1.organization_uid
  end
end
