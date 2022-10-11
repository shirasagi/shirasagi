require 'spec_helper'

describe "gws_schedule_holidays", type: :feature, dbscope: :example, js: true do
  context "add plan" do
    let(:site) { gws_site }
    let(:index_path) { gws_schedule_holidays_path site }
    let!(:item) { create :gws_schedule_holiday }

    before { login_gws_user }

    it "back to index" do
      visit index_path
      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_holiday")
      end
      within "#addon-basic" do
        expect(page).to have_css("[name=\"item[start_on]\"]")
      end

      within ".nav-menu" do
        click_on I18n.t("ss.links.back_to_index")
      end
      expect(current_path).to eq index_path
    end

    it "cancel" do
      visit index_path
      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_holiday")
      end
      within "#addon-basic" do
        expect(page).to have_css("[name=\"item[start_on]\"]")
      end

      within "footer.send" do
        click_on I18n.t("ss.buttons.cancel")
      end
      expect(current_path).to eq index_path
    end

    it "click holiday" do
      visit index_path
      first(".fc-content", text: item.name).click
      expect(current_path).to eq gws_schedule_holiday_path(site, item)
    end
  end
end
