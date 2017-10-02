require 'spec_helper'

describe "gws_shared_address_addresses", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:address_group) { create :gws_shared_address_group }
  let!(:item) { create :gws_shared_address_address, address_group_id: address_group.id }
  let(:index_path) { gws_shared_address_addresses_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it '#crud' do
      visit index_path

      # show
      click_link item.name
      click_link I18n.t('ss.links.back_to_index')

      # group address index
      click_link address_group.name

      # group address show
      click_link item.name
      click_link I18n.t('ss.links.back_to_index')
      first('a', text: I18n.t('modules.gws/shared_address')).click

      expect(current_path).to eq index_path
    end
  end
end
