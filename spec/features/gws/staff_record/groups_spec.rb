require 'spec_helper'

describe "gws_staff_record_public_groups", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:year) { create :gws_staff_record_year }
  let!(:item) { create :gws_staff_record_group, year_id: year.id }
  let(:index_path) { gws_staff_record_groups_path(site, year) }

  context "with auth", js: true do
    before { login_gws_user }

    it_behaves_like 'crud flow'
  end
end
