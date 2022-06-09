require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  context "private plan" do
    let(:site) { gws_site }
    let(:role) { create :gws_role, :gws_role_schedule_plan_editor, cur_site: site }
    let!(:group1) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:group2) { create :gws_group, name: "#{site.name}/#{unique_id}" }
    let!(:user1) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group1.id ] }
    let!(:user2) { create :gws_user, gws_role_ids: [ role.id ], group_ids: [ group2.id ] }
    let!(:private_plan) do
      create(
        :gws_schedule_plan, cur_site: site, cur_user: user1, member_ids: [ user1.id ], member_group_ids: [],
        readable_setting_range: 'private', readable_member_ids: [ user1.id ], readable_group_ids: [],
        group_ids: [ group1.id ], user_ids: [ user1.id ]
      )
    end

    it do
      login_user user2
      visit gws_schedule_user_plans_path(site: site, user: user1)

      within ".fc-day-grid" do
        expect(page).to have_css(".fc-event.fc-event-private", text: I18n.t("gws/schedule.private_plan"))

        # click_on I18n.t("gws/schedule.private_plan")
        first(".fc-event.fc-event-private").click
      end

      within ".gws-popup" do
        expect(page).to have_css(".popup-title", text: I18n.t("gws/schedule.private_plan"))
      end
    end
  end
end
