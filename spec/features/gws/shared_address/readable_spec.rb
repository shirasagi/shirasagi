require 'spec_helper'

describe "gws_shared_address_addresses", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:role) do
    create(
      :gws_role, permissions: %w(
        use_gws_shared_address read_private_gws_shared_address_addresses read_private_gws_shared_address_groups
      )
    )
  end
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ role.id ]) }
  let!(:item) { create :gws_shared_address_address, readable_setting_range: 'public' }
  let!(:closed_item) do
    create :gws_shared_address_address, readable_setting_range: 'select', readable_group_ids: gws_user.group_ids
  end

  before { login_user user1 }

  context "with the address readable by the user" do
    it "#show" do
      visit gws_shared_address_addresses_path(site: site)
      click_on item.name
      expect(status_code).to eq 200
      expect(page).to have_css("#addon-basic", text: item.email)
    end
  end

  context "with the address not readable by the user" do
    it "#show" do
      visit gws_shared_address_addresses_path(site: site)
      expect(page).to have_no_link(closed_item.name)

      visit gws_shared_address_address_path(site: site, id: closed_item)
      expect(status_code).to eq 404
    end
  end
end
