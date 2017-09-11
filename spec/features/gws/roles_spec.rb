require 'spec_helper'

describe "gws_roles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_role }
  let(:index_path) { gws_roles_path site }

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
  end
end
