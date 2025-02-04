require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20250124000000_memo_notice_user_setting_permissions.rb")

RSpec.describe SS::Migration20250124000000, dbscope: :example do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:role1) { gws_user.gws_roles.first }
  let!(:role2) { create :gws_role, permissions: [] }

  let!(:role1_permissions) { role1.permissions }
  let!(:role2_permissions) { %w(edit_gws_memo_notice_user_setting) }

  it do
    expect(role1.permissions).to eq role1_permissions
    expect(role2.permissions).to eq []

    described_class.new.change

    role1.reload
    role2.reload

    expect(role1.permissions).to eq role1_permissions
    expect(role2.permissions).to eq role2_permissions
  end
end
