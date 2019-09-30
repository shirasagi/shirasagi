require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user_683) { affair_user(638) }
    let(:user_545) { affair_user(545) }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }
    let(:logout_path) { gws_logout_path(site: site) }

    def create_overtime_file(start_at, end_at, opts = {})
      name = unique_id
      workflow_comment = unique_id
      approve_comment = unique_id
      week_in_leave_enable = false
      week_out_leave_enable = false
      holiday_compensatory_leave_enable = false

      week_in_compensatory = opts[:week_in_compensatory]
      week_out_compensatory = opts[:week_out_compensatory]
      holiday_compensatory = opts[:holiday_compensatory]

      Timecop.travel(start_at) do
        # request
        login_user(user_683)
        visit new_path

        within "form#item-form" do
          fill_in "item[overtime_name]", with: name

          fill_in "item[start_at_date]", with: start_at.to_date
          select "#{start_at.hour}時", from: 'item[start_at_hour]'
          select "#{start_at.min}分", from: 'item[start_at_minute]'

          fill_in "item[end_at_date]", with: end_at.to_date
          select "#{end_at.hour}時", from: 'item[end_at_hour]'
          select "#{end_at.min}分", from: 'item[end_at_minute]'

          if week_in_compensatory.present?
            compensatory_minute = week_in_compensatory[:minute]
            compensatory_start_at = week_in_compensatory[:start_at]
            compensatory_end_at = week_in_compensatory[:end_at]

            if compensatory_minute
              select compensatory_minute, from: 'item[week_in_compensatory_minute]'
            end
            if compensatory_start_at
              fill_in "item[week_in_start_at_date]", with: compensatory_start_at.to_date
              select "#{compensatory_start_at.hour}時", from: 'item[week_in_start_at_hour]'
              select "#{compensatory_start_at.min}分", from: 'item[week_in_start_at_minute]'
            end
            if compensatory_end_at
              fill_in "item[week_in_end_at_date]", with: compensatory_end_at.to_date
              select "#{compensatory_end_at.hour}時", from: 'item[week_in_end_at_hour]'
              select "#{compensatory_end_at.min}分", from: 'item[week_in_end_at_minute]'
            end

            week_in_leave_enable = true if compensatory_start_at && compensatory_end_at
          end

          if week_out_compensatory.present?
            compensatory_minute = week_out_compensatory[:minute]
            compensatory_start_at = week_out_compensatory[:start_at]
            compensatory_end_at = week_out_compensatory[:end_at]

            if compensatory_minute
              select compensatory_minute, from: 'item[week_out_compensatory_minute]'
            end
            if compensatory_start_at
              fill_in "item[week_out_start_at_date]", with: compensatory_start_at.to_date
              select "#{compensatory_start_at.hour}時", from: 'item[week_out_start_at_hour]'
              select "#{compensatory_start_at.min}分", from: 'item[week_out_start_at_minute]'
            end
            if compensatory_end_at
              fill_in "item[week_out_end_at_date]", with: compensatory_end_at.to_date
              select "#{compensatory_end_at.hour}時", from: 'item[week_out_end_at_hour]'
              select "#{compensatory_end_at.min}分", from: 'item[week_out_end_at_minute]'
            end

            week_out_leave_enable = true if compensatory_start_at && compensatory_end_at
          end

          if holiday_compensatory.present?
            compensatory_minute = holiday_compensatory[:minute]
            compensatory_start_at = holiday_compensatory[:start_at]
            compensatory_end_at = holiday_compensatory[:end_at]

            if compensatory_minute
              select compensatory_minute, from: 'item[holiday_compensatory_minute]'
            end
            if compensatory_start_at
              fill_in "item[holiday_compensatory_start_at_date]", with: compensatory_start_at.to_date
              select "#{compensatory_start_at.hour}時", from: 'item[holiday_compensatory_start_at_hour]'
              select "#{compensatory_start_at.min}分", from: 'item[holiday_compensatory_start_at_minute]'
            end
            if compensatory_end_at
              fill_in "item[holiday_compensatory_end_at_date]", with: compensatory_end_at.to_date
              select "#{compensatory_end_at.hour}時", from: 'item[holiday_compensatory_end_at_hour]'
              select "#{compensatory_end_at.min}分", from: 'item[holiday_compensatory_end_at_minute]'
            end

            holiday_compensatory_leave_enable = true if compensatory_start_at && compensatory_end_at
          end

          click_on I18n.t("ss.buttons.save")
        end
        expect(page).to have_css('#notice', text: "保存しました。")

        within ".mod-workflow-request" do
          select I18n.t("mongoid.attributes.workflow/model/route.my_group"), from: "workflow_route"
          click_on I18n.t("workflow.buttons.select")
          click_on I18n.t("workflow.search_approvers.index")
        end
        wait_for_cbox do
          expect(page).to have_content(user_545.long_name)
          find("tr[data-id='1,#{user_545.id}'] input[type=checkbox]").click
          click_on I18n.t("workflow.search_approvers.select")
        end
        within ".mod-workflow-request" do
          fill_in "workflow[comment]", with: workflow_comment
          click_on I18n.t("workflow.buttons.request")
        end

        # approve
        login_user(user_545)
        visit index_path
        click_on name
        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)

        # input results
        login_user(user_683)
        visit index_path
        click_on name
        within "#addon-gws-agents-addons-affair-overtime_result" do
          click_on "結果を入力する"
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")
          within "#ajax-box" do
            click_on "保存"
          end
        end
        expect(page).to have_css('#notice', text: "保存しました。")

        # edit results
        within "#addon-gws-agents-addons-affair-overtime_result" do
          click_on "結果を編集する"
        end
        wait_for_cbox do
          expect(page).to have_css("#addon-gws-agents-addons-affair-overtime_file")
          within "#ajax-box" do
            click_on "保存"
          end
        end
        expect(page).to have_css('#notice', text: "保存しました。")

        # close results
        login_user(user_545)
        visit index_path
        click_on name
        within "#addon-gws-agents-addons-affair-overtime_result" do
          page.accept_confirm do
            click_on "結果を確認済みにする"
          end
        end
        expect(page).to have_css('#notice', text: "結果を確定しました。")

        # check overtime file
        overtime_file = Gws::Affair::OvertimeFile.find_by(overtime_name: name)
        if week_in_leave_enable
          leave_file = overtime_file.week_in_leave_file
        end
        if week_out_leave_enable
          leave_file = overtime_file.week_out_leave_file
        end
        if holiday_compensatory_leave_enable
          leave_file = overtime_file.holiday_compensatory_leave_file
        end

        if week_in_leave_enable || week_out_leave_enable || holiday_compensatory_leave_enable
          visit index_path
          click_on name

          within "#addon-basic" do
            expect(page).to have_link(leave_file.name)
            click_on leave_file.name

            expect(page).to have_link(overtime_file.name)
            #click_on overtime_file.name
          end
        end
      end

      Gws::Affair::OvertimeFile.find_by(overtime_name: name)
    end

    it "#new" do
      # 2021/1/4 (月) 勤務日 18:00 - 23:00 同一週内振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/4 18:00")
      end_at = Time.zone.parse("2021/1/4 23:00")
      item1 = create_overtime_file(
        start_at,
        end_at,
        week_in_compensatory: {
          minute: "4.0時間",
          start_at: Time.zone.parse("2021/1/5 8:00"),
          end_at: Time.zone.parse("2021/1/5 12:00")
        }
      )

      # 2021/1/10 (日) 週休日 8:00 - 16:00 同一週外振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/10 8:00")
      end_at = Time.zone.parse("2021/01/10 16:00")
      item2 = create_overtime_file(
        start_at,
        end_at,
        week_out_compensatory: {
          minute: "7.75時間",
          start_at: Time.zone.parse("2021/1/18 8:00"),
          end_at: Time.zone.parse("2021/1/18 16:00")
        }
      )

      # 2021/1/11 (金) 祝日 8:00 - 16:00 代休振替 休暇申請有り
      start_at = Time.zone.parse("2021/1/11 8:00")
      end_at = Time.zone.parse("2021/01/11 21:00")
      item3 = create_overtime_file(
        start_at,
        end_at,
        holiday_compensatory: {
          minute: "7.75時間",
          start_at: Time.zone.parse("2021/1/19 8:00"),
          end_at: Time.zone.parse("2021/1/19 16:00")
        }
      )

      # 2021/1/18 (月) 勤務日 18:00 - 24:00 同一週内振替 休暇申請無し
      start_at = Time.zone.parse("2021/1/18 18:00")
      end_at = Time.zone.parse("2021/1/18 24:00")
      item4 = create_overtime_file(
        start_at,
        end_at,
        week_in_compensatory: {
          minute: "4.0時間"
        }
      )

      # 2021/1/19 (火) 勤務日 18:00 - 24:00 同一週外振替 休暇申請無し
      start_at = Time.zone.parse("2021/1/19 18:00")
      end_at = Time.zone.parse("2021/1/19 24:00")
      item5 = create_overtime_file(
        start_at,
        end_at,
        week_out_compensatory: {
          minute: "4.0時間"
        }
      )

      # 2021/2/11 (金) 祝日 8:00 - 20:00 代休振替 休暇申請無し
      start_at = Time.zone.parse("2021/2/11 8:00")
      end_at = Time.zone.parse("2021/2/11 21:00")
      item6 = create_overtime_file(
        start_at,
        end_at,
        holiday_compensatory: {
          minute: "7.75時間"
        }
      )

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
