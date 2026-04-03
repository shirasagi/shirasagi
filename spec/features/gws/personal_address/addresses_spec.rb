require 'spec_helper'

describe "gws_personal_address_addresses", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:address_group) { create :webmail_address_group, cur_user: gws_user }
  let!(:item) { create :webmail_address, address_group_id: address_group.id, cur_user: gws_user }
  let(:index_path) { gws_personal_address_addresses_path(site) }
  let(:new_path) { new_gws_personal_address_address_path(site) }

  before { login_gws_user }

  it_behaves_like 'crud flow'

  context "paste name and email when selected a user" do
    it do
      visit new_path
      within "form#item-form" do
        expect(find('[name="item[name]"]').value).to be_blank
        expect(find('[name="item[email]"]').value).to be_blank
        wait_for_cbox_opened { click_on I18n.t("ss.apis.users.index") }
      end
      within_cbox do
        wait_for_cbox_closed { click_on user.long_name }
      end

      expect(find('[name="item[name]"]').value).to eq user.name
      expect(find('[name="item[email]"]').value).to eq user.email
    end
  end

  context "#download" do
    it do
      visit index_path
      click_link I18n.t('ss.links.download')
      #expect(page.response_headers['Content-Type']).to eq 'text/csv'
    end
  end

  context "#download_template" do
    it do
      visit index_path
      click_link I18n.t('ss.links.import')
      click_link I18n.t('ss.links.download_template')
    end
  end

  context "#import" do
    it do
      visit index_path
      click_link I18n.t('ss.links.import')
      click_button I18n.t('ss.import')
    end
  end
end
