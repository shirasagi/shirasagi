require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user_683) { affair_user(638) }
    let(:user_545) { affair_user(545) }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }

    def create_overtime_file(start_at, end_at, opts = {})
      name = unique_id
      workflow_comment = unique_id
      approve_comment = unique_id
      file = nil

      if opts[:break1_start_at]
        break1_start_at = opts[:break1_start_at]
        break1_end_at = opts[:break1_end_at]
      end

      if opts[:break2_start_at]
        break2_start_at = opts[:break2_start_at]
        break2_end_at = opts[:break2_end_at]
      end

      Timecop.freeze(start_at) do
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

          click_on I18n.t("ss.buttons.save")
        end
        file = Gws::Affair::OvertimeFile.find_by(overtime_name: name)

        login_user(user_683)
        visit index_path
        click_on name

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

          if break1_start_at
            select break1_start_at.strftime("%Y/%m/%d"), from: "item[in_results][#{file.id}][break1_start_at_date]"
            select "#{break1_start_at.hour}時", from: "item[in_results][#{file.id}][break1_start_at_hour]"
            select "#{break1_start_at.min}分", from: "item[in_results][#{file.id}][break1_start_at_minute]"

            select break1_end_at.strftime("%Y/%m/%d"), from: "item[in_results][#{file.id}][break1_end_at_date]"
            select "#{break1_end_at.hour}時", from: "item[in_results][#{file.id}][break1_end_at_hour]"
            select "#{break1_end_at.min}分", from: "item[in_results][#{file.id}][break1_end_at_minute]"
          end

          if break2_start_at
            select break2_start_at.strftime("%Y/%m/%d"), from: "item[in_results][#{file.id}][break2_start_at_date]"
            select "#{break2_start_at.hour}時", from: "item[in_results][#{file.id}][break2_start_at_hour]"
            select "#{break2_start_at.min}分", from: "item[in_results][#{file.id}][break2_start_at_minute]"

            select break2_end_at.strftime("%Y/%m/%d"), from: "item[in_results][#{file.id}][break2_end_at_date]"
            select "#{break2_end_at.hour}時", from: "item[in_results][#{file.id}][break2_end_at_hour]"
            select "#{break2_end_at.min}分", from: "item[in_results][#{file.id}][break2_end_at_minute]"
          end
          within "#ajax-box" do
            click_on "保存"
          end
        end
        expect(page).to have_css('#notice', text: "保存しました。")
      end

      file.reload
      file
    end

    it "#new" do
      # 2021/2/1 (月) 勤務日 17:00 - 24:00 休憩なし
      start_at = Time.zone.parse("2021/2/1 17:00")
      end_at = Time.zone.parse("2021/2/2 00:00")

      item1 = create_overtime_file(start_at, end_at)
      login_user(user_545)
      visit index_path
      click_on item1.name
      within "#addon-gws-agents-addons-affair-overtime_result" do
        expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "5:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "2:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "--:--")
      end

      # 2021/2/2 (火) 勤務日 17:00 - 24:00 休憩なし
      start_at = Time.zone.parse("2021/2/2 17:00")
      end_at = Time.zone.parse("2021/2/3 00:00")

      # 休憩1 17:00 - 17:30
      break1_start_at = Time.zone.parse("2021/2/2 17:00")
      break1_end_at = Time.zone.parse("2021/2/2 17:30")

      item2 = create_overtime_file(start_at, end_at,
        break1_start_at: break1_start_at, break1_end_at: break1_end_at
      )
      login_user(user_545)
      visit index_path
      click_on item2.name
      within "#addon-gws-agents-addons-affair-overtime_result" do
        expect(page).to have_css("table.overtime-results .item td:nth-child(1)", text: "4:30")
        expect(page).to have_css("table.overtime-results .item td:nth-child(2)", text: "2:00")
        expect(page).to have_css("table.overtime-results .item td:nth-child(3)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(4)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(5)", text: "--:--")
        expect(page).to have_css("table.overtime-results .item td:nth-child(6)", text: "0:30")
      end

      # 2021/2/3 (水) 勤務日 17:00 - 翌2:00
      start_at = Time.zone.parse("2021/2/3 17:00")
      end_at = Time.zone.parse("2021/2/4 02:00")

      # 休憩1 17:30 - 18:30
      break1_start_at = Time.zone.parse("2021/2/3 17:30")
      break1_end_at = Time.zone.parse("2021/2/3 18:30")

      # 休憩2 23:30 - 翌0:05
      break2_start_at = Time.zone.parse("2021/2/3 23:30")
      break2_end_at = Time.zone.parse("2021/2/4 00:05")

      item3 = create_overtime_file(start_at, end_at,
        break1_start_at: break1_start_at, break1_end_at: break1_end_at,
        break2_start_at: break2_start_at, break2_end_at: break2_end_at
      )
      login_user(user_545)
      visit index_path
      click_on item3.name
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
