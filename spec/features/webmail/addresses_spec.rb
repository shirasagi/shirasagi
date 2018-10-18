require 'spec_helper'

describe "webmail_addresses", type: :feature, dbscope: :example do
  let(:address_group) { create :webmail_address_group, cur_user: webmail_user }
  let!(:item) { create :webmail_address, cur_user: webmail_user, address_group_id: address_group.id }

  shared_examples "webmail addresses download and import" do
    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')
      #expect(page.response_headers['Content-Type']).to eq 'text/csv'
    end

    it "#import" do
      visit index_path
      within ".nav-menu" do
        click_link I18n.t('ss.links.import')
      end
      click_button I18n.t('ss.import')
    end
  end

  context "with main" do
    let(:index_path) { webmail_addresses_main_path }

    before { login_webmail_user }

    it_behaves_like 'webmail addresses download and import'
  end

  context "with all" do
    let(:index_path) { webmail_addresses_path(group: "-") }

    before { login_webmail_user }

    it_behaves_like 'crud flow'
    it_behaves_like 'webmail addresses download and import'
  end

  context "with specific group" do
    let(:index_path) { webmail_addresses_path(group: address_group.id) }

    before { login_webmail_user }

    it_behaves_like 'crud flow'
  end
end
