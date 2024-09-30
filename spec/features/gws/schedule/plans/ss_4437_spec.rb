require 'spec_helper'

# https://github.com/shirasagi/shirasagi/issues/4437
describe 'gws_schedule_plans', type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:admin) { gws_user }
  let(:group1) { admin.groups.first }
  let(:permissions) do
    %w(
      use_private_gws_schedule_plans
      read_private_gws_schedule_plans
      edit_private_gws_schedule_plans
      delete_private_gws_schedule_plans
    )
  end
  let!(:minimum_role) { create :gws_role, cur_site: site, permissions: permissions }
  let!(:user1) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: [ minimum_role.id ]) }
  let!(:user2) { create(:gws_user, group_ids: [ group1.id ], gws_role_ids: [ minimum_role.id ]) }

  context "a plan doesn't turn to private" do
    let(:name) { "name-#{unique_id}" }

    it do
      login_user user1, ref: gws_schedule_group_plans_path(site: site, group: group1)
      click_on I18n.t("gws/schedule.links.add_plan")
      within "form#item-form" do
        fill_in "item[name]", with: name
        ensure_addon_opened "#addon-gws-agents-addons-group_permission"
        within "#addon-gws-agents-addons-group_permission" do
          within ".mod-gws-owner_permission-groups" do
            click_on I18n.t("ss.buttons.delete")
          end
        end
        wait_for_js_ready
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      within "#cal-#{user1.id}" do
        expect(page).to have_css(".fc-event:not(.fc-holiday)", text: name)
      end

      expect(Gws::Schedule::Plan.all.count).to eq 1
      Gws::Schedule::Plan.all.first.tap do |plan|
        expect(plan.name).to eq name
        expect(plan.user_id).to eq user1.id
        expect(plan.member_ids).to eq [ user1.id ]
        expect(plan.member_group_ids).to be_blank
        expect(plan.member_custom_group_ids).to be_blank
        expect(plan.readable_setting_range).to eq "select"
        expect(plan.readable_member_ids).to be_blank
        expect(plan.readable_group_ids).to eq [ group1.id ]
        expect(plan.readable_custom_group_ids).to be_blank
        expect(plan.user_ids).to eq [ user1.id ]
        expect(plan.group_ids).to be_blank
        expect(plan.custom_group_ids).to be_blank
      end

      # visit gws_schedule_group_plans_path(site: site, group: group1)
      within "#cal-#{user1.id}" do
        # click_on name
        first(".fc-event:not(.fc-holiday)").click
      end
      within ".nav-menu" do
        click_on I18n.t("ss.links.edit")
      end
      within "form#item-form" do
        ensure_addon_opened "#addon-gws-agents-addons-readable_setting"
        within "#addon-gws-agents-addons-readable_setting" do
          choose "item_readable_setting_range_private"
        end
        wait_for_js_ready
        click_on I18n.t("ss.buttons.save")
      end
      wait_for_notice I18n.t("ss.notice.saved")
      within "#cal-#{user1.id}" do
        expect(page).to have_css(".fc-event.fc-event-private", text: name)
      end

      expect(Gws::Schedule::Plan.all.count).to eq 1
      Gws::Schedule::Plan.all.first.tap do |plan|
        expect(plan.name).to eq name
        expect(plan.user_id).to eq user1.id
        expect(plan.readable_setting_range).to eq "private"
        expect(plan.readable_group_ids).to be_blank
        expect(plan.readable_member_ids).to eq [ user1.id ]
        expect(plan.readable_custom_group_ids).to be_blank
      end

      login_user user2, ref: gws_schedule_group_plans_path(site: site, group: group1)
      within "#cal-#{user1.id}" do
        expect(page).to have_css(".fc-event.fc-event-private", text: I18n.t("gws/schedule.private_plan"))
      end
    end
  end
end
