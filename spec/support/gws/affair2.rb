module Gws
  module Affair2Support
    cattr_accessor :data

    module Hooks
      def self.extended(obj)
        dbscope = obj.metadata[:dbscope]
        dbscope ||= RSpec.configuration.default_dbscope

        obj.after(dbscope) do
          Gws::Affair2Support.data = nil
        end
      end
    end
  end
end

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
def gws_affair2_manager_permissions
  %w(
    use_gws_portal_user_settings
    read_private_gws_portal_user_settings
    edit_private_gws_portal_user_settings
    delete_private_gws_portal_user_settings

    use_gws_affair2_attendance_time_cards
    edit_gws_affair2_attendance_time_cards
    manage_sub_gws_affair2_attendance_time_cards

    use_private_gws_affair2_attendance_groups
    use_sub_gws_affair2_attendance_groups

    read_private_gws_affair2_overtime_workday_files
    edit_private_gws_affair2_overtime_workday_files
    delete_private_gws_affair2_overtime_workday_files
    approve_private_gws_affair2_overtime_workday_files
    reroute_private_gws_affair2_overtime_workday_files

    read_private_gws_affair2_overtime_holiday_files
    edit_private_gws_affair2_overtime_holiday_files
    delete_private_gws_affair2_overtime_holiday_files
    approve_private_gws_affair2_overtime_holiday_files
    reroute_private_gws_affair2_overtime_holiday_files

    read_private_gws_affair2_leave_files
    edit_private_gws_affair2_leave_files
    delete_private_gws_affair2_leave_files
    approve_private_gws_affair2_leave_files
    reroute_private_gws_affair2_leave_files

    use_private_gws_affair2_overtime_achieves
    use_sub_gws_affair2_overtime_achieves
    use_private_gws_affair2_leave_achieves
    use_sub_gws_affair2_leave_achieves
  )
end

def gws_affair2_regular_permissions
  %w(
    use_gws_portal_user_settings
    read_private_gws_portal_user_settings
    edit_private_gws_portal_user_settings
    delete_private_gws_portal_user_settings

    use_gws_affair2_attendance_time_cards
    edit_gws_affair2_attendance_time_cards

    use_private_gws_affair2_attendance_groups

    read_private_gws_affair2_overtime_workday_files
    edit_private_gws_affair2_overtime_workday_files
    delete_private_gws_affair2_overtime_workday_files
    reroute_private_gws_affair2_overtime_workday_files

    read_private_gws_affair2_overtime_holiday_files
    edit_private_gws_affair2_overtime_holiday_files
    delete_private_gws_affair2_overtime_holiday_files
    reroute_private_gws_affair2_overtime_holiday_files

    read_private_gws_affair2_leave_files
    edit_private_gws_affair2_leave_files
    delete_private_gws_affair2_leave_files
    reroute_private_gws_affair2_leave_files

    use_private_gws_affair2_overtime_achieves
    use_private_gws_affair2_leave_achieves
  )
end

# 所定時間を自身で決定する（ローテーション勤務者）
def gws_affair2_lotation_permissions
  %w(
    use_gws_portal_user_settings
    read_private_gws_portal_user_settings
    edit_private_gws_portal_user_settings
    delete_private_gws_portal_user_settings

    use_gws_affair2_attendance_time_cards
    edit_gws_affair2_attendance_time_cards
    format_gws_affair2_attendance_time_cards

    use_private_gws_affair2_attendance_groups

    read_private_gws_affair2_overtime_workday_files
    edit_private_gws_affair2_overtime_workday_files
    delete_private_gws_affair2_overtime_workday_files
    reroute_private_gws_affair2_overtime_workday_files

    read_private_gws_affair2_overtime_holiday_files
    edit_private_gws_affair2_overtime_holiday_files
    delete_private_gws_affair2_overtime_holiday_files
    reroute_private_gws_affair2_overtime_holiday_files

    read_private_gws_affair2_leave_files
    edit_private_gws_affair2_leave_files
    delete_private_gws_affair2_leave_files
    reroute_private_gws_affair2_leave_files

    use_private_gws_affair2_overtime_achieves
    use_private_gws_affair2_leave_achieves
  )
end

# タイムカードを自身で変更できない（打刻のみ）
def gws_affair2_restricted_permissions
  %w(
    use_gws_portal_user_settings
    read_private_gws_portal_user_settings
    edit_private_gws_portal_user_settings
    delete_private_gws_portal_user_settings

    use_gws_affair2_attendance_time_cards

    use_private_gws_affair2_attendance_groups

    read_private_gws_affair2_overtime_workday_files
    edit_private_gws_affair2_overtime_workday_files
    delete_private_gws_affair2_overtime_workday_files
    reroute_private_gws_affair2_overtime_workday_files

    read_private_gws_affair2_overtime_holiday_files
    edit_private_gws_affair2_overtime_holiday_files
    delete_private_gws_affair2_overtime_holiday_files
    reroute_private_gws_affair2_overtime_holiday_files

    read_private_gws_affair2_leave_files
    edit_private_gws_affair2_leave_files
    delete_private_gws_affair2_leave_files
    reroute_private_gws_affair2_leave_files

    use_private_gws_affair2_overtime_achieves
    use_private_gws_affair2_leave_achieves
  )
end

def gws_affair2
  return Gws::Affair2Support.data if Gws::Affair2Support.data

  Gws::Affair2Support.data = OpenStruct.new

  site = gws_site

  # role
  roles = OpenStruct.new
  roles.r1 = create(:gws_role, permissions: gws_affair2_manager_permissions)
  roles.r2 = create(:gws_role, permissions: gws_affair2_regular_permissions)
  roles.r3 = create(:gws_role, permissions: gws_affair2_restricted_permissions)
  roles.r4 = create(:gws_role, permissions: gws_affair2_lotation_permissions)

  # group
  groups = OpenStruct.new
  groups.g1     = create :gws_group, name: "#{site.name}/事務部", order: 100
  groups.g1_1   = create :gws_group, name: "#{site.name}/事務部/A課", order: 110
  groups.g1_1_1 = create :gws_group, name: "#{site.name}/事務部/A課/C担当", order: 120
  groups.g1_1_2 = create :gws_group, name: "#{site.name}/事務部/A課/D担当", order: 130
  groups.g1_2   = create :gws_group, name: "#{site.name}/事務部/B課", order: 140
  groups.g1_2_1 = create :gws_group, name: "#{site.name}/事務部/B課/E担当", order: 150
  groups.g1_2_2 = create :gws_group, name: "#{site.name}/事務部/B課/F担当", order: 160

  # user
  users = OpenStruct.new
  users.u1 = create :gws_user, name: "部長", group_ids: [groups.g1.id],
    organization_id: site.id, organization_uid: "0001", gws_role_ids: [roles.r1.id]
  users.u2 = create :gws_user, name: "A課長", group_ids: [groups.g1_1.id],
    organization_id: site.id, organization_uid: "0002", gws_role_ids: [roles.r1.id]
  users.u3 = create :gws_user, name: "C担当1", group_ids: [groups.g1_1_1.id],
    organization_id: site.id, organization_uid: "0003", gws_role_ids: [roles.r2.id]
  users.u4 = create :gws_user, name: "C担当2", group_ids: [groups.g1_1_1.id],
    organization_id: site.id, organization_uid: "0004", gws_role_ids: [roles.r2.id]
  users.u5 = create :gws_user, name: "D担当1(ローテ)", group_ids: [groups.g1_1_2.id],
    organization_id: site.id, organization_uid: "0005", gws_role_ids: [roles.r4.id]
  users.u6 = create :gws_user, name: "D担当2(ローテ)", group_ids: [groups.g1_1_2.id],
    organization_id: site.id, organization_uid: "0006", gws_role_ids: [roles.r4.id]
  users.u7 = create :gws_user, name: "B課長", group_ids: [groups.g1_2.id],
    organization_id: site.id, organization_uid: "0007", gws_role_ids: [roles.r1.id]
  users.u8 = create :gws_user, name: "E担当1", group_ids: [groups.g1_2_1.id],
    organization_id: site.id, organization_uid: "0008", gws_role_ids: [roles.r2.id]
  users.u9 = create :gws_user, name: "E担当2", group_ids: [groups.g1_2_1.id],
    organization_id: site.id, organization_uid: "0009", gws_role_ids: [roles.r2.id]
  users.u10 = create :gws_user, name: "F担当1", group_ids: [groups.g1_2_2.id],
    organization_id: site.id, organization_uid: "0010", gws_role_ids: [roles.r2.id]
  users.u11 = create :gws_user, name: "F担当2", group_ids: [groups.g1_2_2.id],
    organization_id: site.id, organization_uid: "0011", gws_role_ids: [roles.r3.id]
  users.u12 = create :gws_user, name: "AB兼務課長", group_ids: [groups.g1_1.id, groups.g1_2.id],
    organization_id: site.id, organization_uid: "0012", gws_role_ids: [roles.r1.id]

  # special_leave
  special_leave = OpenStruct.new
  special_leave.l1 = create(:gws_affair2_special_leave, order: 10)
  special_leave.l2 = create(:gws_affair2_special_leave, order: 20)
  special_leave.l3 = create(:gws_affair2_special_leave, order: 30)

  # leave_setting
  leave_settings = OpenStruct.new
  leave_settings.s1 = create(:gws_affair2_leave_setting, name: "休暇区分1") # 特別休暇無し
  leave_settings.s2 = create(:gws_affair2_leave_setting, name: "休暇区分2",
    special_leave_ids: [special_leave.l1.id, special_leave.l2.id, special_leave.l3.id]) # 特別休暇有

  # duty_setting
  duty_settings = OpenStruct.new
  duty_settings.s1 = create(:gws_affair2_duty_setting, name: "正規職員1") # 8:30 - 17:15
  duty_settings.s2 = create(:gws_affair2_duty_setting,
    name: "正規職員2",
    start_at_hour: 7, start_at_minute: 45,
    close_at_hour: 16, close_at_minute: 15,
    break_minutes_at: 60) # 7:45～16:15
  duty_settings.s3 = create(:gws_affair2_duty_setting, worktime_type: "variable") # ローテーション勤務者

  # attendance_setting
  in_start_year = 2020
  in_start_month = 1

  attendance_settings = OpenStruct.new
  attendance_settings.u1 = create(:gws_affair2_attendance_setting,
    user: users.u1, organization_uid: users.u1.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u2 = create(:gws_affair2_attendance_setting,
    user: users.u2, organization_uid: users.u2.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u3 = create(:gws_affair2_attendance_setting,
    user: users.u3, organization_uid: users.u3.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u4 = create(:gws_affair2_attendance_setting,
    user: users.u4, organization_uid: users.u4.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u5 = create(:gws_affair2_attendance_setting,
    user: users.u5, organization_uid: users.u5.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s3, leave_setting: leave_settings.s1)
  attendance_settings.u6 = create(:gws_affair2_attendance_setting,
    user: users.u6, organization_uid: users.u6.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s3, leave_setting: leave_settings.s1)
  attendance_settings.u7 = create(:gws_affair2_attendance_setting,
    user: users.u7, organization_uid: users.u7.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u8 = create(:gws_affair2_attendance_setting,
    user: users.u8, organization_uid: users.u8.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u9 = create(:gws_affair2_attendance_setting,
    user: users.u9, organization_uid: users.u9.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)
  attendance_settings.u10 = create(:gws_affair2_attendance_setting,
    user: users.u10, organization_uid: users.u10.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s2, leave_setting: leave_settings.s1)
  attendance_settings.u11 = create(:gws_affair2_attendance_setting,
    user: users.u11, organization_uid: users.u11.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s2, leave_setting: leave_settings.s1)
  attendance_settings.u12 = create(:gws_affair2_attendance_setting,
    user: users.u12, organization_uid: users.u12.organization_uid,
    in_start_year: in_start_year, in_start_month: in_start_month,
    duty_setting: duty_settings.s1, leave_setting: leave_settings.s1)

  # paid_leave_setting
  paid_leave_settings = OpenStruct.new
  paid_leave_settings.u3 = create(:gws_affair2_paid_leave_setting,
    attendance_setting_id: attendance_settings.u3.id,
    year: 2024)
  paid_leave_settings.u3 = create(:gws_affair2_paid_leave_setting,
    attendance_setting_id: attendance_settings.u3.id,
    year: 2025)

  Gws::Affair2Support.data.groups = groups
  Gws::Affair2Support.data.users = users
  Gws::Affair2Support.data.special_leave = special_leave
  Gws::Affair2Support.data.duty_settings = duty_settings
  Gws::Affair2Support.data.leave_settings = leave_settings
  Gws::Affair2Support.data.attendance_settings = attendance_settings
  Gws::Affair2Support.data.paid_leave_settings = paid_leave_settings
  Gws::Affair2Support.data
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength

RSpec.configuration.extend(Gws::Affair2Support::Hooks)
