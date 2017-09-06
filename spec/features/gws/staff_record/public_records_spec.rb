require 'spec_helper'

describe "gws_staff_record_public_records", type: :feature, dbscope: :example do
  let(:site) { gws_site }
  let(:group) { gws_user.groups.first }
  let(:year) { create :gws_staff_record_year }
  let(:section) { create :gws_staff_record_group, year_id: year.id }
  let(:item) { create :gws_staff_record_user, year_id: year.id, section_name: section.name }
  let(:index_path) { gws_staff_record_public_records_path(site, group) }
  let(:show_path) { gws_staff_record_public_records_path(site, group, item) }

  context "with auth", js: true do
    before do
      login_gws_user
      item
    end

    it "#index" do
      visit index_path
      expect(status_code).to eq 200
      expect(current_path).not_to eq sns_login_path
    end
  end
end
