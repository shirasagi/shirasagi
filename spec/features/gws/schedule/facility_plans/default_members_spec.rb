require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:default_member) { create :gws_user, gws_role_ids: user.gws_role_ids, group_ids: user.group_ids }

  let!(:facility) { create :gws_facility_item }
  let!(:item) { create :gws_schedule_facility_plan, facility_ids: [facility.id], member_ids: [user.id] }
  let(:name) { unique_id }

  let(:new_path) { new_gws_schedule_facility_plan_path site, facility }
  let(:edit_path) { edit_gws_schedule_facility_plan_path site, facility, item }

  before { login_gws_user }

  context "no default members" do
    it "#new" do
      visit new_path

      within "form#item-form" do
        fill_in "item[name]", with: name
      end
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      first(".fc-content", text: name).click
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
    end

    it "#edit" do
      visit edit_path

      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      first(".fc-content", text: name).click
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
    end
  end

  context "set default members" do
    before do
      facility.default_member_ids = [default_member.id]
      facility.update!
    end

    it "#new" do
      visit new_path

      within "form#item-form" do
        fill_in "item[name]", with: name
      end
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_text(default_member.long_name)
      end
      within "form#item-form" do
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      first(".fc-content", text: name).click
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_text(default_member.long_name)
      end
    end

    it "#edit" do
      visit edit_path

      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
      within "form#item-form" do
        fill_in "item[name]", with: name
        click_button I18n.t('ss.buttons.save')
      end
      expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

      first(".fc-content", text: name).click
      within "#addon-gws-agents-addons-member" do
        expect(page).to have_text(user.long_name)
        expect(page).to have_no_text(default_member.long_name)
      end
    end
  end
end
