require 'spec_helper'

describe "gws_personal_address_management_group_addresses", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:address_group) { create :webmail_address_group, cur_user: gws_user }
  let!(:item) { create :webmail_address, address_group_id: address_group.id, cur_user: gws_user }
  let(:index_path) { gws_personal_address_group_addresses_path(site, address_group) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')
      #expect(page.response_headers['Content-Type']).to eq 'text/csv'

      visit index_path
      click_link I18n.t('ss.links.import')
      click_button I18n.t('ss.import')
    end
  end
end
