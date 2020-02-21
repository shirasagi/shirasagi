require 'spec_helper'

describe "gws_survey_categories", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:item) { create(:gws_survey_category, cur_site: site) }

  before do
    login_gws_user
  end

  context "crud" do
    it do
      visit gws_survey_categories_path(site: site)

      within ".list-items .list-item" do
        click_on item.name
      end

      within "#addon-basic" do
        expect(page).to have_css("dd", text: item.name)
      end
    end
  end
end
