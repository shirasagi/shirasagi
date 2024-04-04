require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:item) { create :gws_schedule_plan, member_ids: [user.id, user1.id, user2.id] }
  let(:show_path) { gws_schedule_plan_path site, item }

  let!(:user1) { create :gws_user }
  let!(:user2) do
    create(:gws_user,
      kana: unique_id,
      tel: "000-000-0000",
      tel_ext: "000-000-0001",
      title_ids: [title.id],
      occupation_ids: [occupation.id])
  end

  let!(:title) { create :gws_user_title }
  let!(:occupation) { create :gws_user_occupation }

  context "basic crud" do
    before { login_gws_user }

    it "#crud" do
      visit show_path

      within "#addon-gws-agents-addons-member" do
        first(".user-detail", text: user1.name).click
      end
      wait_for_cbox do
        expect(page).to have_text(user1.name)
        expect(page).to have_text(user1.groups.first.name)
        click_on I18n.t("ss.buttons.close")
      end
      within "#addon-gws-agents-addons-member" do
        first(".user-detail", text: user2.name).click
      end
      wait_for_cbox do
        expect(page).to have_text(user2.name)
        expect(page).to have_text(user2.kana)
        expect(page).to have_text(user2.tel)
        expect(page).to have_text(user2.tel_ext)
        expect(page).to have_text(user2.title(site).name)
        expect(page).to have_text(user2.occupation(site).name)
        expect(page).to have_text(user2.groups.first.name)
      end
    end
  end
end
