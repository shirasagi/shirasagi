require 'spec_helper'

describe Sys::UserExporter, dbscope: :example do
  let!(:role1) { create :sys_role_admin, name: "管理者", cur_user: nil }
  let!(:role2) { create :sys_role_general, name: "一般ユーザー", cur_user: nil }

  let!(:group1) { create :ss_group, name: 'グループ1' }
  let!(:group2) { create :ss_group, name: 'グループ1/グループ2' }

  let(:user1) do
    create(:ss_user,
      uid: "uid1",
      organization_uid: "0000001",
      email: "user1@example.jp",
      in_password: "pass",
      name: "ユーザー1",
      kana: "ゆーざー1",
      tel: "0000001",
      tel_ext: "0000004",
      type: "sns",
      account_start_date: nil,
      account_expiration_date: nil,
      initial_password_warning: nil,
      session_lifetime: nil,
      restriction: nil,
      lock_state: nil,
      deletion_lock_state: nil,
      organization_id: group1.id,
      group_ids: [group1.id],
      remark: nil,
      lang: nil,
      timezone: "Tokyo",
      ldap_dn: nil,
      sys_role_ids: [role1.id])
  end
  let(:user2) do
    create(:ss_user,
    uid: "uid2",
    organization_uid: "0000002",
    email: "user2@example.jp",
    in_password: nil,
    name: "ユーザー2",
    kana: "ゆーざー2",
    tel: "0000002",
    tel_ext: "0000005",
    type: "sso",
    account_start_date: nil,
    account_expiration_date: Time.zone.parse("2030/9/1 11:00:00"),
    initial_password_warning: nil,
    session_lifetime: 1000,
    restriction: "api_only",
    lock_state: "unlocked",
    deletion_lock_state: "unlocked",
    organization_id: group1.id,
    group_ids: [group2.id],
    remark: "備考です",
    lang: "ja",
    timezone: "Tokyo",
    ldap_dn: nil,
    sys_role_ids: [role2.id])
  end
  let(:user3) do
    create(:ss_user,
      uid: "uid3",
      organization_uid: "0000003",
      email: "user3@example.jp",
      in_password: nil,
      name: "ユーザー3",
      kana: "ゆーざー3",
      tel: "0000003",
      tel_ext: "0000006",
      type: "ldap",
      account_start_date: Time.zone.parse("2020/9/1 11:00:00"),
      account_expiration_date: Time.zone.parse("2030/9/1 11:00:00"),
      initial_password_warning: nil,
      session_lifetime: 3000,
      restriction: "none",
      lock_state: "locked",
      deletion_lock_state: "locked",
      organization_id: group1.id,
      group_ids: [group2.id],
      remark: "備考です",
      lang: "en",
      timezone: "Abu Dhabi",
      ldap_dn: "dc=example,dc=jp",
      sys_role_ids: [role2.id])
  end

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/sys/user_exporter/sys_users.csv" }

  it do
    user1
    user2
    user3
    expect(SS::User.pluck(:uid)).to match_array %w(uid1 uid2 uid3)

    csv = CSV.read(csv_path, headers: true)
    # do export csv from Sys::UserExporter.
    # and check exported data equal to readed csv
  end
end
