require 'spec_helper'

describe "webmail_addresses", type: :feature, dbscope: :example do
  let(:address_group) { create :webmail_address_group }
  let!(:item) { create :webmail_address, cur_user: webmail_user, address_group_id: address_group.id }

  shared_examples "webmail addresses flow" do
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

  describe "webmail_mode is account" do
    let(:index_path) { webmail_addresses_path(account: 0) }

    it_behaves_like 'webmail addresses flow'
  end

  describe "webmail_mode is group" do
    let(:group) { create :webmail_group }
    let(:index_path) { webmail_addresses_path(account: group.id, webmail_mode: :group) }

    before { webmail_user.add_to_set(group_ids: [ group.id ]) }

    it_behaves_like 'webmail addresses flow'
  end
end
