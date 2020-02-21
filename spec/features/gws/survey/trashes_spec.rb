require 'spec_helper'

describe "gws_survey_trashes", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:item) { create(:gws_survey_form) }

  before do
    login_gws_user
    item.deleted = Time.zone.now
    item.save
  end

  context "crud" do
    it do
      visit gws_survey_trashes_path(site: site)

      within ".list-items .list-item" do
        click_on item.name
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: item.name)
      end
    end
  end
end
