require 'spec_helper'

describe "gws_staff_record_public_seatings", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:year) { create :gws_staff_record_year }
  let!(:item) { create :gws_staff_record_seating, year_id: year.id }
  let(:index_path) { gws_staff_record_seatings_path(site, year) }

  context "with auth", js: true do
    before { login_gws_user }

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
