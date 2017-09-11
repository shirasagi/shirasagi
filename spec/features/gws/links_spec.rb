require 'spec_helper'

describe "gws_links", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_link }
  let(:index_path) { gws_links_path site }
  let(:public_index_path) { gws_public_links_path site }

  context "with auth" do
    before { login_gws_user }

    it "#index" do
      visit index_path

      # new/create
      click_link I18n.t('ss.links.new')
      click_button I18n.t('ss.buttons.save')

      # show
      click_link I18n.t('ss.links.back_to_index')
      click_link item.name

      # edit/update
      click_link I18n.t('ss.links.edit')
      click_button I18n.t('ss.buttons.save')

      # delete/destroy
      click_link I18n.t('ss.links.delete')
      click_button I18n.t('ss.buttons.delete')

      expect(status_code).to eq 200
      expect(current_path).to eq index_path
    end

    it "#public_index" do
      visit public_index_path
      expect(status_code).to eq 200

      click_link item.name
      expect(status_code).to eq 200
    end
  end
end
