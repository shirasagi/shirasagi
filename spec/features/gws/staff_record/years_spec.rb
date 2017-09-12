require 'spec_helper'

describe "gws_staff_record_public_records", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let!(:item) { create :gws_staff_record_year }
  let(:index_path) { gws_staff_record_years_path(site) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'
  end
end
