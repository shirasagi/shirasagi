require 'spec_helper'

describe "webmail_group_addresses", type: :feature, dbscope: :example do
  let(:address_group) { create :webmail_address_group, cur_user: webmail_user }
  let!(:item) { create :webmail_address, cur_user: webmail_user, address_group_id: address_group.id }
  let(:index_path) { webmail_address_group_addresses_path(account: 0, address_group: address_group.id) }

  context "with auth" do
    before { login_webmail_user }

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
