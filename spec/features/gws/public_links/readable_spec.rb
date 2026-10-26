require 'spec_helper'

describe "gws_public_links", type: :feature, dbscope: :example do
  let!(:site) { gws_site }
  let!(:g1) { create(:gws_group, name: "#{site.name}/g-#{unique_id}") }
  let!(:role) { create(:gws_role, permissions: %w(read_private_gws_links)) }
  let!(:user1) { create(:gws_user, group_ids: [ g1.id ], gws_role_ids: [ role.id ]) }
  let!(:item) { create :gws_link, state: 'public', readable_setting_range: 'public' }
  let!(:closed_item) do
    create :gws_link, state: 'public', readable_setting_range: 'select', readable_group_ids: gws_user.group_ids
  end

  before { login_user user1 }

  context "with the link readable by the user" do
    it "#show" do
      visit gws_public_links_path(site: site)
      click_on item.name
      expect(status_code).to eq 200
      expect(page).to have_css(".main-box h2", text: item.name)
    end
  end

  context "with the link not readable by the user" do
    it "#show" do
      visit gws_public_links_path(site: site)
      expect(page).to have_no_link(closed_item.name)

      visit gws_public_link_path(site: site, id: closed_item)
      expect(status_code).to eq 404
    end
  end
end
