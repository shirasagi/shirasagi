require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user638) { affair_user(638) }
    let(:user545) { affair_user(545) }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }

    def create_overtime_file(start_at, end_at)
      name = unique_id

      Timecop.freeze(start_at) do
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

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      Gws::Affair::OvertimeFile.find_by(overtime_name: name)
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

    def input_results(item)
      start_at = item.start_at

      Timecop.freeze(start_at) do
        login_user(user638)
        visit index_path
        click_on item.name
        wait_for_js_ready
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_cbox_open { click_on I18n.t("gws/affair.links.set_results") }
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")
          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def edit_results_break1(item, break_start, break_end)
      start_at = item.start_at

      Timecop.freeze(start_at) do
        login_user(user638)
        visit index_path
        click_on item.name
        wait_for_js_ready
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_cbox_open { click_on I18n.t("gws/affair.links.edit_results") }
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")

          select break_start.strftime("%Y/%m/%d"), from: "item[in_results][#{item.id}][break1_start_at_date]"
          select I18n.t('gws/attendance.hour', count: break_start.hour),
            from: "item[in_results][#{item.id}][break1_start_at_hour]"
          select I18n.t('gws/attendance.minute', count: break_start.min),
            from: "item[in_results][#{item.id}][break1_start_at_minute]"

          select break_end.strftime("%Y/%m/%d"), from: "item[in_results][#{item.id}][break1_end_at_date]"
          select I18n.t('gws/attendance.hour', count: break_end.hour),
            from: "item[in_results][#{item.id}][break1_end_at_hour]"
          select I18n.t('gws/attendance.minute', count: break_end.min),
            from: "item[in_results][#{item.id}][break1_end_at_minute]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def edit_results_break2(item, break_start, break_end)
      start_at = item.start_at

      Timecop.freeze(start_at) do
        login_user(user638)
        visit index_path
        click_on item.name
        wait_for_js_ready
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_cbox_open { click_on I18n.t("gws/affair.links.edit_results") }
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")

          select break_start.strftime("%Y/%m/%d"), from: "item[in_results][#{item.id}][break2_start_at_date]"
          select I18n.t('gws/attendance.hour', count: break_start.hour),
            from: "item[in_results][#{item.id}][break2_start_at_hour]"
          select I18n.t('gws/attendance.minute', count: break_start.min),
            from: "item[in_results][#{item.id}][break2_start_at_minute]"

          select break_end.strftime("%Y/%m/%d"), from: "item[in_results][#{item.id}][break2_end_at_date]"
          select I18n.t('gws/attendance.hour', count: break_end.hour),
            from: "item[in_results][#{item.id}][break2_end_at_hour]"
          select I18n.t('gws/attendance.minute', count: break_end.min),
            from: "item[in_results][#{item.id}][break2_end_at_minute]"

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def close_results(item)
      start_at = item.start_at

      Timecop.freeze(start_at) do
        login_user(user545)
        visit index_path
        click_on item.name
        wait_for_js_ready
        within "#addon-gws-agents-addons-affair-overtime_result" do
          page.accept_confirm do
            click_on I18n.t("gws/affair.links.close_results")
          end
        end
        wait_for_notice I18n.t("gws/affair.notice.close_results")
      end
      item.reload
      item
    end

    it "#new" do
      # 2021/2/1 (月) 勤務日 17:00 - 24:00
      # 休憩なし
      start_at = Time.zone.parse("2021/2/1 17:00")
      end_at = Time.zone.parse("2021/2/2 00:00")

      item1 = create_overtime_file(start_at, end_at)
      item1 = request_file(item1)
      item1 = approve_file(item1)
      item1 = input_results(item1)
      item1 = close_results(item1)

      login_user(user545)
      visit index_path
      click_on item1.name
      wait_for_js_ready
      within "#addon-gws-agents-addons-affair-overtime_result" do
        expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "5:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "2:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "--:--")
      end

      # 2021/2/2 (火) 勤務日 17:00 - 24:00 休憩なし
      # 休憩1 17:00 - 17:30
      start_at = Time.zone.parse("2021/2/2 17:00")
      end_at = Time.zone.parse("2021/2/3 00:00")
      break1_start_at = Time.zone.parse("2021/2/2 17:00")
      break1_end_at = Time.zone.parse("2021/2/2 17:30")

      item2 = create_overtime_file(start_at, end_at)
      item2 = request_file(item2)
      item2 = approve_file(item2)
      item2 = input_results(item2)
      item2 = edit_results_break1(item2, break1_start_at, break1_end_at)
      item2 = close_results(item2)

      login_user(user545)
      visit index_path
      click_on item2.name
      wait_for_js_ready
      within "#addon-gws-agents-addons-affair-overtime_result" do
        expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "4:30")
        expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "2:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "0:30")
      end

      # 2021/2/3 (水) 勤務日 17:00 - 翌2:00
      # 休憩1 17:30 - 18:30
      # 休憩2 23:30 - 翌0:05
      start_at = Time.zone.parse("2021/2/3 17:00")
      end_at = Time.zone.parse("2021/2/4 02:00")
      break1_start_at = Time.zone.parse("2021/2/3 17:30")
      break1_end_at = Time.zone.parse("2021/2/3 18:30")
      break2_start_at = Time.zone.parse("2021/2/3 23:30")
      break2_end_at = Time.zone.parse("2021/2/4 00:05")

      item3 = create_overtime_file(start_at, end_at)
      item3 = request_file(item3)
      item3 = approve_file(item3)
      item3 = input_results(item3)
      item3 = edit_results_break1(item3, break1_start_at, break1_end_at)
      item3 = edit_results_break2(item3, break2_start_at, break2_end_at)
      item3 = close_results(item3)

      login_user(user545)
      visit index_path
      click_on item3.name
      wait_for_js_ready
      within "#addon-gws-agents-addons-affair-overtime_result" do
        expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "4:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "3:25")
        expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "1:35")
      end
    end
  end
end
