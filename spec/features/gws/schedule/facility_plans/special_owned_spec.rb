require 'spec_helper'

describe "gws_schedule_facility_plans", type: :feature, dbscope: :example, js: true do
  let!(:site) { gws_site }
  let!(:user) { gws_user }

  let!(:private_permissions) do
    %w(
      read_private_gws_schedule_plans edit_private_gws_schedule_plans
      delete_private_gws_schedule_plans use_private_gws_facility_plans
      read_private_gws_facility_items
    )
  end
  let!(:role) { create :gws_role, permissions: private_permissions }

  let!(:user1) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role.id] }
  let!(:user2) { create :gws_user, group_ids: user.group_ids, gws_role_ids: [role.id] }

  context "default settings" do
    context "with auth" do
      before { login_user user1 }

      context "user1 has facility permission and plan is readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", group_ids: user.group_ids }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_truthy
          expect(item.readable?(user1)).to be_truthy
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: item.name)
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end

      context "user1 has facility permission and plan is not readable (but it owned)" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", group_ids: user.group_ids }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ], readable_setting_range: "private" }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_truthy
          expect(item.readable?(user1)).to be_falsey
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end

      context "user1 has not facility permission and plan is readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", user_ids: [user2.id] }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_falsey
          expect(item.readable?(user1)).to be_truthy
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: item.name)
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end

      context "user1 has not facility permission and plan is not readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", user_ids: [user2.id] }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ], readable_setting_range: "private" }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_falsey
          expect(item.readable?(user1)).to be_falsey
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end
    end
  end

  context "set special owned" do
    before do
      @save_facility_plans = SS.config.gws.facility_plans
      SS.config.replace_value_at(:gws, :facility_plans, { "owned" => "facility" })
    end

    after do
      SS.config.replace_value_at(:gws, :facility_plans, @save_facility_plans)
    end

    context "with auth" do
      before { login_user user1 }

      context "user1 has facility permission and plan is readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", group_ids: user.group_ids }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_truthy
          expect(item.readable?(user1)).to be_truthy
          expect(item.owned?(user1)).to be_truthy

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: item.name)
          end

          # update
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within ".nav-menu" do
            click_on I18n.t("ss.links.edit")
          end
          within "form#item-form" do
            click_button I18n.t('ss.buttons.save')
          end
          wait_for_notice I18n.t('ss.notice.saved')

          # delete
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within ".nav-menu" do
            click_link I18n.t('ss.links.delete')
          end
          within "form#item-form" do
            click_button I18n.t('ss.buttons.delete')
          end
          wait_for_notice I18n.t('ss.notice.deleted')
        end
      end

      context "user1 has facility permission and plan is not readable (but it owned)" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", group_ids: user.group_ids }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ], readable_setting_range: "private" }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_truthy
          expect(item.readable?(user1)).to be_truthy
          expect(item.owned?(user1)).to be_truthy

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: item.name)
          end

          # update
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within ".nav-menu" do
            click_on I18n.t("ss.links.edit")
          end
          within "form#item-form" do
            click_button I18n.t('ss.buttons.save')
          end
          wait_for_notice I18n.t('ss.notice.saved')

          # delete
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within ".nav-menu" do
            click_link I18n.t('ss.links.delete')
          end
          within "form#item-form" do
            click_button I18n.t('ss.buttons.delete')
          end
          wait_for_notice I18n.t('ss.notice.deleted')
        end
      end

      context "user1 has not facility permission and plan is readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", user_ids: [user2.id] }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ] }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_falsey
          expect(item.readable?(user1)).to be_truthy
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: item.name)
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end

      context "user1 has not facility permission and plan is not readable" do
        let!(:facility) { create :gws_facility_item, readable_setting_range: "public", user_ids: [user2.id] }
        let!(:item) { create :gws_schedule_facility_plan, facility_ids: [ facility.id ], readable_setting_range: "private" }

        it do
          expect(facility.readable?(user1)).to be_truthy
          expect(facility.owned?(user1)).to be_falsey
          expect(item.readable?(user1)).to be_falsey
          expect(item.owned?(user1)).to be_falsey

          # show
          visit gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          within "#addon-basic" do
            expect(page).to have_css("dd", text: I18n.t("gws/schedule.private_plan"))
          end
          within ".nav-menu" do
            have_no_link I18n.t("ss.links.edit")
            have_no_link I18n.t("ss.links.delete")
          end

          # update
          visit edit_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))

          # delete
          visit soft_delete_gws_schedule_facility_plan_path(site: site, facility: facility, id: item)
          expect(page).to have_css('#addon-basic .addon-head', text: I18n.t("ss.rescues.default.head"))
        end
      end
    end
  end
end
