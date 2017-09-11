require 'spec_helper'

describe "gws_staff_record_public_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:year) { create :gws_staff_record_year }
  let!(:item) { create :gws_staff_record_group, year_id: year.id }
  let(:index_path) { gws_staff_record_groups_path(site, year) }

  context "with auth", js: true do
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
