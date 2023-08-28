require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user638) { affair_user(638) }
    let(:user545) { affair_user(545) }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }
    let(:logout_path) { gws_logout_path(site: site) }

    it "#new" do
      # 同一週内振替 休暇申請有り
      # 2021/2/20 (土) 勤務日 13：00 - 18：00
      # 2021/2/19 (金) 振替日 13：00 - 17：00
      start_at              = Time.zone.parse("2021/2/20 13:00")
      end_at                = Time.zone.parse("2021/2/20 18:00")

      compensatory_minute   = "4.0#{I18n.t("ss.hours")}"
      compensatory_start_at = Time.zone.parse("2021/2/19 13:00")
      compensatory_end_at   = Time.zone.parse("2021/2/19 17:00")

      name = unique_id
      workflow_comment = unique_id
      approve_comment = unique_id

      Timecop.travel(start_at) do
        # request
        login_user(user638)
        visit new_path

        within "form#item-form" do
          expect(page).to have_css(".selected-capital", text: user638.effective_capital(site).name)
          fill_in "item[overtime_name]", with: name

          fill_in_date "item[start_at_date]", with: start_at.to_date
          select I18n.t('gws/attendance.hour', count: start_at.hour), from: 'item[start_at_hour]'
          select I18n.t('gws/attendance.minute', count: start_at.min), from: 'item[start_at_minute]'

          fill_in_date "item[end_at_date]", with: end_at.to_date
          select I18n.t('gws/attendance.hour', count: end_at.hour), from: 'item[end_at_hour]'
          select I18n.t('gws/attendance.minute', count: end_at.min), from: 'item[end_at_minute]'

          js_select compensatory_minute, from: 'item[week_in_compensatory_minute]'

          find('[name="item[overtime_name]"]').click
          within "dd.week-in-compensatory" do
            find("a.open-compensatory").click
          end

          fill_in_date "item[week_in_start_at_date]", with: compensatory_start_at.to_date
          select I18n.t('gws/attendance.hour', count: compensatory_start_at.hour), from: 'item[week_in_start_at_hour]'
          select I18n.t('gws/attendance.minute', count: compensatory_start_at.min), from: 'item[week_in_start_at_minute]'

          fill_in_date "item[week_in_end_at_date]", with: compensatory_end_at.to_date
          select I18n.t('gws/attendance.hour', count: compensatory_end_at.hour), from: 'item[week_in_end_at_hour]'
          select I18n.t('gws/attendance.minute', count: compensatory_end_at.min), from: 'item[week_in_end_at_minute]'

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))
        wait_for_js_ready

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
        expect(page).to have_css(".mod-workflow-view dd", text: I18n.t("workflow.state.request"))
        expect(page).to have_css(".mod-workflow-view dd", text: workflow_comment)
        wait_for_js_ready

        # approve
        login_user(user545)
        visit index_path
        click_on name
        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)
        wait_for_js_ready

        # input results
        login_user(user638)
        visit index_path
        click_on name
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_for_js_ready
          wait_cbox_open { click_on I18n.t("gws/affair.links.set_results") }
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")
          within "#ajax-box" do
            click_on I18n.t("ss.buttons.save")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_js_ready

        # edit results
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_for_js_ready
          wait_cbox_open { click_on I18n.t("gws/affair.links.edit_results") }
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")
          within "#ajax-box" do
            click_on I18n.t("ss.buttons.save")
          end
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_js_ready

        # close results
        login_user(user545)
        visit index_path
        click_on name
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_for_js_ready
          page.accept_confirm do
            click_on I18n.t("gws/affair.links.close_results")
          end
        end
        wait_for_notice I18n.t("gws/affair.notice.close_results")
        wait_for_js_ready

        within "#addon-gws-agents-addons-affair-overtime_result" do
          expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "1:00")
          expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "--:--")
          expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
          expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
          expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
          expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "4:00")
          expect(page).to have_css("table.overtime-results .item td:nth-child(7)", text: "--:--")
        end
      end
    end
  end
end
