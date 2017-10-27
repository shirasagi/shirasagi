require 'spec_helper'

describe "webmail_addresses", type: :feature, dbscope: :example do
  let(:address_group) { create :webmail_address_group }
  let!(:item) { create :webmail_address, address_group_id: address_group.id }
  let(:index_path) { webmail_addresses_path(account: 0) }

  context "with auth" do
    before { login_ss_user }

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
