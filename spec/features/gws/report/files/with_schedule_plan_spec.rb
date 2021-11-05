require 'spec_helper'

describe "gws_report_files", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let!(:category) { create :gws_report_category, cur_site: site }
  let!(:form) { create :gws_report_form, cur_site: site, category_ids: [ category.id ], state: "public" }
  let!(:column1) do
    create(:gws_column_text_field, cur_site: site, form: form, order: 10, required: "optional", input_type: "text")
  end

  context "with gws/schedule/plan" do
    let(:plan_name) { unique_id }
    let(:report_name) { unique_id }

    context "select existing report/file" do
      let!(:group1) { create(:gws_group, name: "#{gws_site.name}/#{unique_id}") }
      let!(:group2) { create(:gws_group, name: "#{gws_site.name}/#{unique_id}") }
      let!(:user0) { create(:gws_user, group_ids: [ gws_site.id ], gws_role_ids: gws_user.gws_role_ids) }
      let!(:user1) { create(:gws_user, group_ids: [ gws_site.id ], gws_role_ids: gws_user.gws_role_ids) }
      let!(:user2) { create(:gws_user, group_ids: [ gws_site.id ], gws_role_ids: gws_user.gws_role_ids) }
      let!(:file1) do
        create(
          :gws_report_file, cur_site: site, cur_user: user0, group_ids: user0.group_ids, user_ids: [ user0.id ],
          state: "closed", member_ids: [ user0.id, user1.id, user2.id ],
          readable_setting_range: "select", readable_member_ids: [ user0.id, user1.id, user2.id ]
        )
      end
      let!(:file2) do
        create(
          :gws_report_file, cur_site: site, cur_user: user0, group_ids: user0.group_ids, user_ids: [ user0.id ],
          state: "public", member_ids: [ user1.id ], readable_setting_range: "select", readable_member_ids: [ user2.id ]
        )
      end
      let!(:file3) do
        create(
          :gws_report_file, cur_site: site, cur_user: user1, group_ids: user1.group_ids, user_ids: [ user1.id ],
          state: "public", member_ids: [ user2.id ], readable_setting_range: "select", readable_member_ids: [ user0.id ]
        )
      end
      let!(:file4) do
        create(
          :gws_report_file, cur_site: site, cur_user: user2, group_ids: user2.group_ids, user_ids: [ user2.id ],
          state: "public", member_ids: [ user0.id ], readable_setting_range: "select", readable_member_ids: [ user1.id ]
        )
      end

      before { login_user user0 }

      it do
        visit gws_schedule_main_path(site: site)
        within ".gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end

        within "form#item-form" do
          fill_in "item[name]", with: plan_name
          click_on I18n.t("gws/report.apis.files.index")
        end

        wait_for_cbox do
          within ".index .items" do
            # file1 is unable to view because file1 is closed
            expect(page).to have_no_css(".list-item", text: file1.name)
            # file2 is able to view because file2's users contains user0
            expect(page).to have_css(".list-item", text: file2.name)
            # file3 is able to view because file3's readable users contains user0
            expect(page).to have_css(".list-item", text: file3.name)
            # file4 is able to view because file4's members contains user0
            expect(page).to have_css(".list-item", text: file4.name)

            click_on file2.name
          end
        end

        within "form#item-form" do
          within "#addon-gws-agents-addons-schedule-reports" do
            expect(page).to have_css(".ajax-selected", text: file2.name)
          end
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        within ".fc-view-container" do
          expect(page).to have_css(".fc-title", text: plan_name)
        end

        expect(Gws::Schedule::Plan.all.count).to eq 1
        plan = Gws::Schedule::Plan.site(site).find_by(name: plan_name)

        file2.reload
        expect(file2.schedule_ids).to include(plan.id)

        # view schedule/plan
        visit gws_schedule_plan_path(site: site, id: plan)
        within "#addon-gws-agents-addons-schedule-reports" do
          expect(page).to have_css(".index", text: file2.name)
        end

        # view report/file
        within "#addon-gws-agents-addons-schedule-reports" do
          click_on file2.name
        end
        within "#addon-gws-agents-addons-schedules" do
          expect(page).to have_css(".index", text: plan.name)
        end
      end
    end

    context "create schedule/plan and then create report/file" do
      before { login_gws_user }

      it do
        # create schedule/plan
        visit gws_schedule_main_path(site: site)
        within ".gws-schedule-box" do
          click_on I18n.t("gws/schedule.links.add_plan")
        end

        within "form#item-form" do
          fill_in "item[name]", with: plan_name
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))
        within ".fc-view-container" do
          expect(page).to have_css(".fc-title", text: plan_name)
        end

        expect(Gws::Schedule::Plan.all.count).to eq 1
        plan = Gws::Schedule::Plan.site(site).find_by(name: plan_name)

        # and then create report/files
        visit gws_schedule_plan_path(site: site, id: plan)
        within "#menu" do
          # click_on I18n.t("gws/schedule.links.create_reports")
          first("a.dropdown-toggle").click
          within ".gws-dropdown-menu" do
            click_on form.name
          end
        end
        within "form#item-form" do
          fill_in "item[name]", with: report_name
          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: I18n.t('ss.notice.saved'))

        expect(Gws::Report::File.all.count).to eq 1
        report_file = Gws::Report::File.site(site).find_by(name: report_name)
        expect(report_file.schedule_ids).to include(plan.id)
        expect(report_file.state).to eq "closed"

        # view schedule/plan
        visit gws_schedule_plan_path(site: site, id: plan)
        within "#addon-gws-agents-addons-schedule-reports" do
          expect(page).to have_css(".index", text: report_file.name)
        end

        # view report/file
        visit gws_report_files_main_path(site: site)
        within ".current-navi" do
          click_on I18n.t('gws/report.options.file_state.closed')
        end
        click_on report_file.name
        within "#addon-gws-agents-addons-schedules" do
          expect(page).to have_css(".index", text: plan.name)
        end
      end
    end
  end
end
