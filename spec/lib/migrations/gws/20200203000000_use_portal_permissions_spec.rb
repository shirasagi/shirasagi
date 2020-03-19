require 'spec_helper'
require Rails.root.join("lib/migrations/gws/20200203000000_use_portal_permissions.rb")

RSpec.describe SS::Migration20200203000000, dbscope: :example do
  let(:site) { gws_site }
  let!(:role1) { create :gws_role }
  let!(:role2) { create :gws_role_admin }

  before do
    described_class.new.change
  end

  it do
    role1.reload
    expect(role1.permissions).to include("use_gws_portal_user_settings", "use_gws_portal_group_settings",
                                         "use_gws_portal_organization_settings")

    role2.reload
    expect(role2.permissions).to include("use_gws_portal_user_settings", "use_gws_portal_group_settings",
                                         "use_gws_portal_organization_settings")
  end
end
