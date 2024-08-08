require 'spec_helper'

describe "gws_schedule_facilities", type: :feature, dbscope: :example, js: true do
  context "add plan" do
    let!(:site) { gws_site }
    let!(:cate1) { create :gws_facility_category, cur_site: site, order: 1 }
    let!(:cate2) { create :gws_facility_category, cur_site: site, order: 2 }
    let!(:facility1) { create :gws_facility_item, cur_site: site, order: 1, category: cate1 }
    let!(:facility2) { create :gws_facility_item, cur_site: site, order: 2, category: cate2 }
    let!(:index_path) { gws_schedule_facilities_path site }

    let!(:name1) { unique_id }
    let!(:name2) { unique_id }

    before { login_gws_user }

    it "#index" do
      visit index_path
      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      select "+---- #{cate1.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      select "+---- #{cate2.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end
    end

    it "create plan" do
      visit index_path

      # cate1
      select "+---- #{cate1.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within "form#item-form" do
        fill_in "item[name]", with: name1
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
        expect(page).to have_css(".fc-content", text: name1)
      end

      # cate2
      select "+---- #{cate2.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within "form#item-form" do
        fill_in "item[name]", with: name2
        click_button I18n.t('ss.buttons.save')
      end
      wait_for_js_ready
      wait_for_notice I18n.t('ss.notice.saved')

      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
        expect(page).to have_no_css(".fc-content", text: name1)
        expect(page).to have_css(".fc-content", text: name2)
      end
    end

    it "back to index" do
      visit index_path

      # cate1
      select "+---- #{cate1.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within ".nav-menu" do
        click_on I18n.t("ss.links.back_to_index")
      end

      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      # cate2
      select "+---- #{cate2.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within ".nav-menu" do
        click_on I18n.t("ss.links.back_to_index")
      end

      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end
    end

    it "cancel" do
      visit index_path

      # cate1
      select "+---- #{cate1.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within "footer.send" do
        click_on I18n.t("ss.buttons.cancel")
      end

      within ".gws-schedule-box" do
        expect(page).to have_link facility1.name
        expect(page).to have_no_link facility2.name
      end

      # cate2
      select "+---- #{cate2.name}", from: "s[facility_category_id]"
      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end

      within ".gws-schedule-box" do
        click_on I18n.t("gws/schedule.links.add_plan")
      end
      wait_for_js_ready

      within "footer.send" do
        click_on I18n.t("ss.buttons.cancel")
      end

      within ".gws-schedule-box" do
        expect(page).to have_no_link facility1.name
        expect(page).to have_link facility2.name
      end
    end
  end
end
