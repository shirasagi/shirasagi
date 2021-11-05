require 'spec_helper'
require Rails.root.join("lib/migrations/inquiry/20210212000000_fix_inquiry_permissions.rb")

RSpec.describe SS::Migration20210212000000, dbscope: :example do
  let(:site)   { cms_site }
  let(:all_permissions) { Cms::Role.permission_names }
  let(:inquiry_permissions) { all_permissions.select { |name| name =~ /_inquiry_(columns|answers)$/ } }

  let(:role1) do
    create(:cms_role,
      name: "role1",
      permissions: all_permissions,
      permission_level: 3,
      cur_site: site
    )
  end
  let(:role2) do
    create(:cms_role,
      name: "role2",
      permissions: (all_permissions - inquiry_permissions),
      permission_level: 1,
      cur_site: site
    )
  end

  it do
    # created at 2020/12/31
    Timecop.travel("2020/12/31") do
      role1
      role2
    end
    described_class.new.change

    role1.reload
    role2.reload

    expect(role1.permissions).to match_array all_permissions
    expect(role2.permissions).to match_array all_permissions
  end

  it do
    # created at 2021/2/31
    Timecop.travel("2021/2/13") do
      role1
      role2
    end
    described_class.new.change

    role1.reload
    role2.reload

    expect(role1.permissions).to match_array all_permissions
    expect(role2.permissions).to match_array(all_permissions - inquiry_permissions)
  end
end
