require 'spec_helper'

describe "gws_staff_record_public_seatings", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:year) { create :gws_staff_record_year }
  let!(:item) { create :gws_staff_record_seating, year_id: year.id }
  let(:index_path) { gws_staff_record_public_seatings_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it "#index" do
      visit index_path
      expect(current_path).not_to eq sns_login_path
    end
  end
end
