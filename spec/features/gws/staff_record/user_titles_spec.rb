require 'spec_helper'

describe "gws_staff_record_public_user_titles", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:year) { create :gws_staff_record_year }
  let(:section) { create :gws_staff_record_group, year_id: year.id }
  let!(:item) { create :gws_staff_record_user_title, year_id: year.id }
  let(:index_path) { gws_staff_record_user_titles_path(site, year) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'

    it "#download" do
      visit index_path
      click_link I18n.t('ss.links.download')

      visit index_path
      click_link I18n.t('ss.links.import')
      click_button I18n.t('ss.import')
    end
  end
end
