require 'spec_helper'

describe "gws_affair_leave_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user_638) { affair_user(638) }
    let(:user_545) { affair_user(545) }

    let(:year) { Gws::Affair::CapitalYear.first }
    let(:leave_setting) { create(:gws_affair_leave_setting, site: site, year: year, target_user: user_638) }

    let(:new_path) { new_gws_affair_leave_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_leave_files_path(site: site, state: "all") }
    let(:aggregate_path) { gws_affair_leave_aggregate_path(site: site) }

    def create_special_leave_file(start_at, end_at)
      reason = unique_id
      workflow_comment = unique_id
      approve_comment = unique_id

      Timecop.freeze(start_at) do
        # request
        login_user(user_638)
        visit new_path

        within "form#item-form" do
          fill_in "item[start_at_date]", with: start_at.to_date
          select "#{start_at.hour}時", from: 'item[start_at_hour]'
          select "#{start_at.min}分", from: 'item[start_at_minute]'

          fill_in "item[end_at_date]", with: end_at.to_date
          select "#{end_at.hour}時", from: 'item[end_at_hour]'
          select "#{end_at.min}分", from: 'item[end_at_minute]'

          fill_in "item[reason]", with: reason
          select "特別休暇", from: 'item[leave_type]'

          click_on I18n.t("gws/affair.apis.special_leaves.index")
        end
        wait_for_cbox do
          click_on "病気休暇（公務）"
        end
        within "form#item-form" do
          click_on I18n.t("ss.buttons.save")
        end

        login_user(user_638)
        visit index_path

        item = Gws::Affair::LeaveFile.find_by(reason: reason)
        click_on item.name

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
        click_on item.name
        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
        expect(page).to have_css(".mod-workflow-view dd", text: /#{::Regexp.escape(approve_comment)}/)
      end

      Gws::Affair::LeaveFile.find_by(reason: reason)
    end

    it "#new" do
      leave_setting

      # 2021/1/4 (月) 勤務日 8:30 - 20:00
      start_at = Time.zone.parse("2021/1/4 8:30")
      end_at = Time.zone.parse("2021/1/4 20:00")
      item1 = create_special_leave_file(start_at, end_at)

      login_user(user_545)
      visit aggregate_path

      within ".gws-attendance" do
        within "table.index" do
          expect(page).to have_link user_545.long_name
        end

        # change group
        within "form" do
          select user_638.groups.first.name, from: 'group_id'
          click_on "検索"
        end

        within "table.index" do
          expect(page).to have_link user_638.long_name
          click_on user_638.long_name
        end
      end

      within ".gws-attendance" do
        # change year month
        within "form" do
          select "2021年", from: 'year'
          select "1月", from: 'month'
          click_on "検索"
        end
      end

      within "#annual-leave-setting" do
        expect(page).to have_css(".leave-dates", text: "20日")
        expect(page).to have_css(".leave-minutes", text: "155時間（9300分）")
        expect(page).to have_css(".effective-leave-minutes", text: "155時間（9300分）")
      end

      within "#annual-leave" do
        expect(page).to have_css("dd", text: "申請はありません。")
        expect(page).to have_css(".leave-minutes", text: "0時間（0分）")
      end

      within "#paid-leave" do
        expect(page).to have_css(".leave-minutes", text: "7.75時間（465分）")
        within ".leave-files" do
          expect(page).to have_link item1.name
        end
      end
    end
  end
end
