require 'spec_helper'

describe Sys::UserImporter, dbscope: :example do
  let!(:role1) { create :sys_role_admin, name: "管理者", cur_user: nil }
  let!(:role2) { create :sys_role_general, name: "一般ユーザー", cur_user: nil }

  let!(:group1) { create :ss_group, name: 'グループ1' }
  let!(:group2) { create :ss_group, name: 'グループ1/グループ2' }

  let(:user1) { create(:ss_user, uid: "uid1", email: nil, type: "sns", in_password: "pass") }
  let(:user2) { create(:ss_user, uid: "uid2", email: nil, type: "sso", in_password: nil) }
  let(:user3) { create(:ss_user, uid: "uid3", email: nil, type: "ldap", in_password: nil) }

  let!(:csv_path) { "#{Rails.root}/spec/fixtures/sys/user_importer/sys_users.csv" }

  it do
    user1
    user2
    user3
    expect(SS::User.pluck(:uid)).to match_array %w(uid1 uid2 uid3)

    # do import fixture's csv.
    # and check attributes of imported users.
    expect(SS::User.pluck(:uid)).to match_array %w(uid1 uid2 uid3 uid4)

    # user1, user2, user3 are updated.
    # user4 is new created.
  end
end
