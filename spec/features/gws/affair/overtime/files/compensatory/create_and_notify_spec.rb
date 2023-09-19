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

    def create_overtime_file(start_at, end_at, confirmation = nil)
      name = unique_id
      travel_at = start_at

      Timecop.freeze(travel_at) do
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

        if confirmation
          wait_for_cbox do
            expect(page).to have_css("p", text: I18n.t("gws/affair.form_alert.title.overtime_compensatory"))
            click_on I18n.t("ss.buttons.save")
          end
        end

        wait_for_notice I18n.t("ss.notice.saved")
      end
      Gws::Affair::OvertimeFile.find_by(overtime_name: name)
    end

    def edit_week_in_compensatory(item, minute, start_at = nil, end_at = nil)
      travel_at = item.start_at

      Timecop.travel(travel_at) do
        login_user(user638)
        visit index_path

        click_on item.name
        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready

        within "form#item-form" do
          expect(page).to have_css(".selected-capital", text: user638.effective_capital(site).name)
          js_select minute, from: 'item[week_in_compensatory_minute]'

          find('[name="item[overtime_name]"]').click
          within "dd.week-in-compensatory" do
            find("a.open-compensatory").click
          end
          wait_for_js_ready

          if start_at
            fill_in_date "item[week_in_start_at_date]", with: start_at.to_date
            select I18n.t('gws/attendance.hour', count: start_at.hour), from: 'item[week_in_start_at_hour]'
            select I18n.t('gws/attendance.minute', count: start_at.min), from: 'item[week_in_start_at_minute]'
          end

          if end_at
            fill_in_date "item[week_in_end_at_date]", with: end_at.to_date
            select I18n.t('gws/attendance.hour', count: end_at.hour), from: 'item[week_in_end_at_hour]'
            select I18n.t('gws/attendance.minute', count: end_at.min), from: 'item[week_in_end_at_minute]'
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def edit_week_out_compensatory(item, minute, start_at = nil, end_at = nil)
      travel_at = item.start_at

      Timecop.travel(travel_at) do
        login_user(user638)
        visit index_path

        click_on item.name
        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready

        within "form#item-form" do
          select minute, from: 'item[week_out_compensatory_minute]'

          find('[name="item[overtime_name]"]').click
          wait_for_js_ready

          within "dd.week-out-compensatory" do
            find("a.open-compensatory").click
          end
          wait_for_js_ready

          if start_at
            fill_in_date "item[week_out_start_at_date]", with: start_at.to_date
            select I18n.t('gws/attendance.hour', count: start_at.hour), from: 'item[week_out_start_at_hour]'
            select I18n.t('gws/attendance.minute', count: start_at.min), from: 'item[week_in_start_at_minute]'
          end

          if end_at
            fill_in_date "item[week_out_end_at_date]", with: end_at.to_date
            select I18n.t('gws/attendance.hour', count: end_at.hour), from: 'item[week_out_end_at_hour]'
            select I18n.t('gws/attendance.minute', count: end_at.min), from: 'item[week_out_end_at_minute]'
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def edit_holiday_compensatory(item, minute, start_at = nil, end_at = nil)
      travel_at = item.start_at

      Timecop.travel(travel_at) do
        login_user(user638)
        visit index_path

        click_on item.name
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

        within ".nav-menu" do
          click_on I18n.t("ss.links.edit")
        end
        wait_for_js_ready

        within "form#item-form" do
          select minute, from: 'item[holiday_compensatory_minute]'

          find('[name="item[overtime_name]"]').click
          wait_for_js_ready

          within "dd.holiday-compensatory" do
            find("a.open-compensatory").click
          end
          wait_for_js_ready

          if start_at
            fill_in_date "item[holiday_compensatory_start_at_date]", with: start_at.to_date
            select I18n.t('gws/attendance.hour', count: start_at.hour), from: 'item[holiday_compensatory_start_at_hour]'
            select I18n.t('gws/attendance.minute', count: start_at.min), from: 'item[holiday_compensatory_start_at_minute]'
          end

          if end_at
            fill_in_date "item[holiday_compensatory_end_at_date]", with: end_at.to_date
            select I18n.t('gws/attendance.hour', count: end_at.hour), from: 'item[holiday_compensatory_end_at_hour]'
            select I18n.t('gws/attendance.minute', count: end_at.min), from: 'item[holiday_compensatory_end_at_minute]'
          end

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
      end
      item.reload
      item
    end

    def request_file(item)
      travel_at = item.start_at
      workflow_comment = unique_id

      Timecop.freeze(travel_at) do
        login_user(user638)
        visit index_path

        click_on item.name
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
      travel_at = item.start_at
      approve_comment = unique_id

      Timecop.freeze(travel_at) do
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
      travel_at = item.start_at

      Timecop.freeze(travel_at) do
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

    def close_results(item)
      travel_at = item.start_at

      Timecop.freeze(travel_at) do
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

    def check_leave_file(item, leave_file)
      travel_at = item.start_at

      Timecop.freeze(travel_at) do
        login_user(user545)
        visit index_path
        click_on item.name
        wait_for_js_ready

        within "#addon-basic" do
          expect(page).to have_link(leave_file.name)
          click_on leave_file.name
          wait_for_js_ready

          expect(page).to have_link(item.name)
          click_on item.name
        end
        wait_for_js_ready
      end
      item
    end

    it "#new" do
      # 2021/1/4 (月) 勤務日 18:00 - 23:00
      # 同一週内振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/4 18:00")
      end_at = Time.zone.parse("2021/1/4 23:00")
      compensatory_minute = "4.0#{I18n.t("ss.hours")}"
      compensatory_start_at = Time.zone.parse("2021/1/5 8:00")
      compensatory_end_at = Time.zone.parse("2021/1/5 12:00")

      item1 = create_overtime_file(start_at, end_at)
      item1 = edit_week_in_compensatory(item1, compensatory_minute, compensatory_start_at, compensatory_end_at)
      item1 = request_file(item1)
      item1 = approve_file(item1)
      item1 = input_results(item1)
      item1 = close_results(item1)
      item1 = check_leave_file(item1, item1.week_in_leave_file)

      # 2021/1/10 (日) 週休日 8:00 - 16:00
      # 同一週外振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/10 8:00")
      end_at = Time.zone.parse("2021/01/10 16:00")
      compensatory_minute = "7.75#{I18n.t("ss.hours")}"
      compensatory_start_at = Time.zone.parse("2021/1/18 8:00")
      compensatory_end_at = Time.zone.parse("2021/1/18 16:00")

      item2 = create_overtime_file(start_at, end_at, true)
      item2 = edit_week_out_compensatory(item2, compensatory_minute, compensatory_start_at, compensatory_end_at)
      item2 = request_file(item2)
      item2 = approve_file(item2)
      item2 = input_results(item2)
      item2 = close_results(item2)
      item2 = check_leave_file(item2, item2.week_out_leave_file)

      # 2021/1/11 (金) 祝日 8:00 - 16:00
      # 代休振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/11 8:00")
      end_at = Time.zone.parse("2021/01/11 21:00")
      compensatory_minute = "7.75#{I18n.t("ss.hours")}"
      compensatory_start_at = Time.zone.parse("2021/1/19 8:00")
      compensatory_end_at = Time.zone.parse("2021/1/19 16:00")

      item3 = create_overtime_file(start_at, end_at, true)
      item3 = edit_holiday_compensatory(item3, compensatory_minute, compensatory_start_at, compensatory_end_at)
      item3 = request_file(item3)
      item3 = approve_file(item3)
      item3 = input_results(item3)
      item3 = close_results(item3)
      item3 = check_leave_file(item3, item3.holiday_compensatory_leave_file)

      # 2021/1/18 (月) 勤務日 18:00 - 24:00
      # 同一週内振替 休暇申請無し
      start_at = Time.zone.parse("2021/1/18 18:00")
      end_at = Time.zone.parse("2021/1/18 24:00")
      compensatory_minute = "4.0#{I18n.t("ss.hours")}"

      item4 = create_overtime_file(start_at, end_at)
      item4 = edit_week_in_compensatory(item4, compensatory_minute)
      item4 = request_file(item4)
      item4 = approve_file(item4)
      item4 = input_results(item4)
      item4 = close_results(item4)

      # 2021/1/19 (火) 勤務日 18:00 - 24:00
      # 同一週外振替 休暇申請無し
      start_at = Time.zone.parse("2021/1/19 18:00")
      end_at = Time.zone.parse("2021/1/19 24:00")
      compensatory_minute = "4.0#{I18n.t("ss.hours")}"

      item5 = create_overtime_file(start_at, end_at)
      item5 = edit_week_out_compensatory(item5, compensatory_minute)
      item5 = request_file(item5)
      item5 = approve_file(item5)
      item5 = input_results(item5)
      item5 = close_results(item5)

      # 2021/2/11 (金) 祝日 8:00 - 20:00
      # 代休振替 休暇申請無し
      start_at = Time.zone.parse("2021/2/11 8:00")
      end_at = Time.zone.parse("2021/2/11 21:00")
      compensatory_minute = "7.75#{I18n.t("ss.hours")}"

      item6 = create_overtime_file(start_at, end_at, true)
      item6 = edit_holiday_compensatory(item6, compensatory_minute)
      item6 = request_file(item6)
      item6 = approve_file(item6)
      item6 = input_results(item6)
      item6 = close_results(item6)

      # notify
      # 週外振替、代休振替の有効期限は申請の 前4週 後8週 通知は期限日の７日前
      # 週内振替の通知はなし
      Timecop.freeze("2021/3/6 8:00") do
        ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now

        names = SS::Notification.all.map(&:name)
        expect(names.count("[時間外申請] 時間外申請「#{item1.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item2.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item3.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item4.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item5.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item6.name}」振替の有効期限が迫っています。")).to be 0
      end
      Timecop.freeze("2021/3/8 8:00") do
        ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now

        names = SS::Notification.all.map(&:name)
        expect(names.count("[時間外申請] 時間外申請「#{item1.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item2.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item3.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item4.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item5.name}」振替の有効期限が迫っています。")).to be 1
        expect(names.count("[時間外申請] 時間外申請「#{item6.name}」振替の有効期限が迫っています。")).to be 0
      end
      Timecop.freeze("2021/3/31 8:00") do
        ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now

        names = SS::Notification.all.map(&:name)
        expect(names.count("[時間外申請] 時間外申請「#{item1.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item2.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item3.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item4.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item5.name}」振替の有効期限が迫っています。")).to be 1
        expect(names.count("[時間外申請] 時間外申請「#{item6.name}」振替の有効期限が迫っています。")).to be 1
      end
      Timecop.freeze("2021/4/1 8:00") do
        ::Gws::Affair::NotifyCompensatoryFileJob.bind(site_id: site.id).perform_now

        names = SS::Notification.all.map(&:name)
        expect(names.count("[時間外申請] 時間外申請「#{item1.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item2.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item3.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item4.name}」振替の有効期限が迫っています。")).to be 0
        expect(names.count("[時間外申請] 時間外申請「#{item5.name}」振替の有効期限が迫っています。")).to be 1
        expect(names.count("[時間外申請] 時間外申請「#{item6.name}」振替の有効期限が迫っています。")).to be 1
      end
    end
  end
end
