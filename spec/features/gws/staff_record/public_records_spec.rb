require 'spec_helper'

describe "gws_staff_record_public_records", type: :feature, dbscope: :example do
  let(:site) { gws_site }

  before { login_gws_user }

  context "with item" do
    let(:year) { create :gws_staff_record_year }
    let(:section) { create :gws_staff_record_group, year_id: year.id }
    let!(:item) do
      create(
        :gws_staff_record_user, year_id: year.id, section_name: section.name,
        staff_records_view: "show", divide_duties_view: "show"
      )
    end

    it do
      visit gws_staff_record_public_records_path(site)
      expect(current_path).not_to eq sns_login_path

      # show
      click_link item.charge_name
    end
  end

  context "without item" do
    it do
      visit gws_staff_record_public_records_path(site)
      expect(page).to have_content(I18n.t('gws/staff_record.errors.no_data'))
      expect(page).to have_css("#crumbs", text: I18n.t("gws/staff_record.staff_records"))
    end
  end
end
