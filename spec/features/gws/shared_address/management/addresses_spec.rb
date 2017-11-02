require 'spec_helper'

describe "gws_shared_address_management_addresses", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:address_group) { create :gws_shared_address_group }
  let!(:item) { create :gws_shared_address_address, address_group_id: address_group.id }
  let(:index_path) { gws_shared_address_management_addresses_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')
      #expect(page.response_headers['Content-Type']).to eq 'text/csv'

      visit "#{index_path}/download_template"

      visit index_path
      click_link I18n.t('ss.links.import')
      click_button I18n.t('ss.import')
    end
  end
end
