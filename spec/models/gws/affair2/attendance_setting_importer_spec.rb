require 'spec_helper'

describe Gws::Affair2::AttendanceSettingImporter, type: :model, dbscope: :example do
  let!(:site) { gws_site }
  let!(:affair2) { gws_affair2 }

  let!(:user_u2) { affair2.users.u2 }
  let!(:attendance_u2) { affair2.attendance_settings.u2 }
  let!(:duty_setting1) { affair2.duty_settings.s1 }
  let!(:duty_setting2) { affair2.duty_settings.s2 }
  let!(:leave_setting1) { affair2.leave_settings.s1 }
  let!(:leave_setting2) { affair2.leave_settings.s2 }

  context "usual case" do
    let(:today) { Time.zone.today }
    let(:headers) { %w(id ユーザー 職員番号 開始 終了 雇用区分 休暇区分) }
    # u2の勤務を今月で終了にする
    let(:user_u2_update_attendance_line) do
      [
        attendance_u2.id,
        "#{user_u2.id},#{user_u2.name}",
        user_u2.organization_uid,
        today.strftime("%Y/%m"),
        today.strftime("%Y/%m"),
        duty_setting1.name,
        leave_setting1.name
      ]
    end
    # u2に来月の勤務追加する
    let(:user_u2_new_attendance_line) do
      [
        nil,
        "#{user_u2.id},#{user_u2.name}",
        user_u2.organization_uid,
        today.next_month.strftime("%Y/%m"),
        nil,
        duty_setting2.name,
        leave_setting2.name
      ]
    end
    let(:csv) do
      CSV.generate do |data|
        data << headers
        data << user_u2_update_attendance_line
        data << user_u2_new_attendance_line
      end
    end
    let(:in_file) do
      tmp_file = Fs::UploadedFile.new
      tmp_file.original_filename = "temp.csv"
      tmp_file.write(csv)
      tmp_file.rewind
      tmp_file
    end

    it do
      item = described_class.new(cur_site: site, in_file: in_file)
      expect(item.import).to be_truthy
      expect(item.errors).to be_blank

      attendance_settings = Gws::Affair2::AttendanceSetting.user(user_u2).to_a
      expect(attendance_settings.count).to eq 2

      expect(attendance_settings[0].start_date.to_date).to eq today.next_month.change(day: 1).to_date
      expect(attendance_settings[0].close_date).to eq nil
      expect(attendance_settings[0].duty_setting.id).to eq duty_setting2.id
      expect(attendance_settings[0].leave_setting.id).to eq leave_setting2.id

      expect(attendance_settings[1].start_date.to_date).to eq today.change(day: 1).to_date
      expect(attendance_settings[1].close_date.to_date).to eq today.end_of_month.to_date
      expect(attendance_settings[1].duty_setting.id).to eq duty_setting1.id
      expect(attendance_settings[1].leave_setting.id).to eq leave_setting1.id
    end
  end

  context "error case" do
    let(:today) { Time.zone.today }
    let(:headers) { %w(id ユーザー 職員番号 開始 終了 雇用区分 休暇区分) }
    let(:user_id_and_name) { "#{unique_id},#{unique_id}" }
    let(:invalid_user_line) do
      [
        nil,
        user_id_and_name,
        unique_id,
        today.strftime("%Y/%m"),
        nil,
        duty_setting1.name,
        leave_setting1.name
      ]
    end
    let(:csv) do
      CSV.generate do |data|
        data << headers
        data << invalid_user_line
      end
    end
    let(:in_file) do
      tmp_file = Fs::UploadedFile.new
      tmp_file.original_filename = "temp.csv"
      tmp_file.write(csv)
      tmp_file.rewind
      tmp_file
    end
    it do
      item = described_class.new(cur_site: site, in_file: in_file)
      expect(item.import).to be_falsey
      expect(item.errors.count).to eq 1
      expect(item.errors.full_messages[0]).to eq "1行目: ユーザーが見つかりません。(#{user_id_and_name})"
    end
  end
end
