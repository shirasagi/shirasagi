require 'spec_helper'

describe "gws_user_titles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :ss_user_title, group_id: gws_user.group_ids.first }
  let(:index_path) { gws_user_titles_path site }

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
  end
end
