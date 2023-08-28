require 'spec_helper'

describe "gws_affair_leave_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user638) { affair_user(638) }
    let(:user545) { affair_user(545) }

    let(:year) { Gws::Affair::CapitalYear.first }
    let(:leave_setting) { create(:gws_affair_leave_setting, site: site, year: year, target_user: user638) }

    let(:new_path) { new_gws_affair_leave_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_leave_files_path(site: site, state: "all") }
    let(:details_path) { gws_affair_leave_details_path(site: site) }

    def create_special_leave_file(start_at, end_at)
      reason = unique_id

      Timecop.freeze(start_at) do
        login_user(user638)
        visit new_path

        within "form#item-form" do
          fill_in_date "item[start_at_date]", with: start_at.to_date
          select I18n.t("gws/attendance.hour", count: start_at.hour), from: 'item[start_at_hour]'
          select I18n.t("gws/attendance.minute", count: start_at.min), from: 'item[start_at_minute]'

          fill_in_date "item[end_at_date]", with: end_at.to_date
          select I18n.t("gws/attendance.hour", count: end_at.hour), from: 'item[end_at_hour]'
          select I18n.t("gws/attendance.minute", count: end_at.min), from: 'item[end_at_minute]'

          # within "#addon-gws-agents-addons-file .toggle-head" do
          #   find('h2', text: I18n.t("modules.addons.gws/file")).click
          # end

          fill_in "item[reason]", with: reason
          select I18n.t("gws/affair.options.leave_type.paidleave"), from: 'item[leave_type]'

          wait_cbox_open { click_on I18n.t("gws/affair.apis.special_leaves.index") }
        end
        wait_for_cbox do
          wait_cbox_close { click_on "病気休暇（公務）" }
        end
        within "form#item-form" do
          expect(page).to have_css(".select-special-leave", text: "病気休暇（公務）")
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      Gws::Affair::LeaveFile.site(site).find_by(reason: reason)
    end

    def request_file(item)
      start_at = item.start_at
      workflow_comment = unique_id

      Timecop.freeze(start_at) do
        login_user(user638)
        visit index_path

        click_on item.name

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          wait_cbox_open { click_on I18n.t("workflow.search_approvers.index") }
        end
        wait_for_cbox do
          expect(page).to have_content(user545.long_name)
          find("tr[data-id='1,#{user545.id}'] input[type=checkbox]").click
          wait_cbox_close { click_on I18n.t("workflow.search_approvers.select") }
        end
        within ".mod-workflow-request" do
          expect(page).to have_css(".approvers [data-id='1,#{user545.id}']", text: user545.long_name)
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end
        wait_for_js_ready

        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        within "#addon-basic" do
          expect(page).to have_css("dd", text: I18n.t("gws/affair.options.status.request"))
        end
      end
      item.reload
      item
    end

    def approve_file(item)
      start_at = item.start_at
      approve_comment = unique_id

      Timecop.freeze(start_at) do
        login_user(user545)
        visit index_path
        click_on item.name
        wait_for_js_ready

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        wait_for_js_ready

        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)
      end
      item.reload
      item
    end

    it "#new" do
      leave_setting

      # 2021/1/4 (月) 勤務日 8:30 - 20:00
      start_at = Time.zone.parse("2021/1/4 8:30")
      end_at = Time.zone.parse("2021/1/4 20:00")
      item1 = create_special_leave_file(start_at, end_at)
      item1 = request_file(item1)
      item1 = approve_file(item1)

      login_user(user545)
      visit details_path

      within ".gws-attendance" do
        within "table.index" do
          expect(page).to have_link user545.long_name
        end

        # change group
        within "form" do
          select user638.groups.first.name, from: 'group_id'
          click_on I18n.t('ss.buttons.search')
        end
        wait_for_js_ready

        within "table.index" do
          expect(page).to have_link user638.long_name
          click_on user638.long_name
        end
        wait_for_js_ready
      end

      within ".gws-attendance" do
        # change year month
        within "form" do
          select I18n.t("gws/attendance.year", count: start_at.year), from: 'year'
          select I18n.t("gws/attendance.month", count: start_at.month), from: 'month'
          click_on I18n.t('ss.buttons.search')
        end
        wait_for_js_ready
      end

      within "#annual-leave-setting" do
        expect(page).to have_css(".leave-dates",
          text: "20#{I18n.t("ss.options.datetime_unit.day")}")
        expect(page).to have_css(".leave-minutes",
          text: "155#{I18n.t("ss.hours")}(9300#{I18n.t("datetime.prompts.minute")})")
        expect(page).to have_css(".effective-leave-minutes",
          text: "155#{I18n.t("ss.hours")}(9300#{I18n.t("datetime.prompts.minute")})")
      end

      within "#annual-leave" do
        expect(page).to have_css("dd", text: I18n.t("gws/affair.notice.not_found_leave_files"))
        expect(page).to have_css(".leave-minutes",
          text: "0#{I18n.t("ss.hours")}(0#{I18n.t("datetime.prompts.minute")})")
      end

      within "#paid-leave" do
        expect(page).to have_css(".leave-minutes",
          text: "7.75#{I18n.t("ss.hours")}(465#{I18n.t("datetime.prompts.minute")})")
        within ".leave-files" do
          expect(page).to have_link item1.name
        end
      end
    end
  end
end
