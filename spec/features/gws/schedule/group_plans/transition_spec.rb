require 'spec_helper'

describe "gws_schedule_group_plans", type: :feature, dbscope: :example, js: true do
  context "add plan" do
    let(:site) { gws_site }
    let(:group) { gws_user.groups.first }
    let(:index_path) { gws_schedule_group_plans_path site, group }

    before { login_gws_user }

    it "back to index" do
      visit index_path
      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "#addon-basic" do
        expect(page).to have_css("[name=\"item[start_at]\"]")
      end

      within ".nav-menu" do
        click_on I18n.t("ss.links.back_to_index")
      end
      expect(current_path).to eq index_path
    end

    it "cancel" do
      visit index_path
      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      within "#addon-basic" do
        expect(page).to have_css("[name=\"item[start_at]\"]")
      end

      within "footer.send" do
        click_on I18n.t("ss.buttons.cancel")
      end
      expect(current_path).to eq index_path
    end
  end
end
