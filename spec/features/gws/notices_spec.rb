require 'spec_helper'

describe "gws_notices", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_notice }
  let(:index_path) { gws_notices_path(site) }
  let(:public_index_path) { gws_public_notices_path(site) }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(status_code).to eq 200

      # new/create
      click_link I18n.t('ss.links.new')
      click_button I18n.t('ss.buttons.save')
      click_link I18n.t('ss.links.back_to_index')

      # show
      click_link item.name
      expect(status_code).to eq 200

      # edit/update
      click_link I18n.t('ss.links.edit')
      click_button I18n.t('ss.buttons.save')
      expect(status_code).to eq 200

      # delete/destroy
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')
      expect(status_code).to eq 200
    end

    it "#public_index" do
      visit public_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end
  end
end
