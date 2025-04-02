require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20231101000000_add_edit_cms_ignore_syntax_check_permission.rb")

RSpec.describe SS::Migration20231101000000, dbscope: :example do
  let(:site)   { cms_site }
  let(:all_permissions) { Cms::Role.permission_names }
  let(:add_permissions) { %w(edit_cms_ignore_syntax_check) }

  let(:role1) do
    create(:cms_role,
      name: "role1",
      permissions: all_permissions,
      cur_site: site
    )
  end
  let(:role2) do
    create(:cms_role,
      name: "role2",
      permissions: (all_permissions - add_permissions),
      cur_site: site
    )
  end

  it do
    Timecop.travel("2023/10/31") do
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
    Timecop.travel("2023/11/30") do
      role1
      role2
    end
    described_class.new.change

    role1.reload
    role2.reload

    expect(role1.permissions).to match_array all_permissions
    expect(role2.permissions).to match_array all_permissions
  end
end
