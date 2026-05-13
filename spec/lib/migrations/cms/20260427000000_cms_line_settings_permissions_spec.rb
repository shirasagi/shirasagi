require 'spec_helper'
require Rails.root.join("lib/migrations/cms/20260427000000_cms_line_settings_permissions.rb")

RSpec.describe SS::Migration20260427000000, dbscope: :example do
  let!(:site) { cms_site }
  let!(:role1) { create :cms_role, cur_site: site, name: unique_id, permissions: %w(use_private_cms_line_messages) }
  let!(:role2) { create :cms_role, cur_site: site, name: unique_id, permissions: %w(use_other_cms_line_messages) }
  let!(:role3) { create :cms_role, cur_site: site, name: unique_id, permissions: (Cms::Role.permission_names - [name]) }
  let!(:role4) { create :cms_role, cur_site: site, name: unique_id, permissions: Cms::Role.permission_names }
  let!(:name) { "use_cms_line_settings" }

  it do
    expect(role1.permissions).not_to include(name)
    expect(role2.permissions).not_to include(name)
    expect(role3.permissions).not_to include(name)
    expect(role4.permissions).to include(name)

    described_class.new.change

    role1.reload
    role2.reload
    role3.reload
    role4.reload

    expect(role1.permissions).to match_array(%w(use_private_cms_line_messages))
    expect(role2.permissions).to match_array(%w(use_other_cms_line_messages) + [name])
    expect(role3.permissions).to match_array(Cms::Role.permission_names)
    expect(role4.permissions).to match_array(Cms::Role.permission_names)
  end
end
