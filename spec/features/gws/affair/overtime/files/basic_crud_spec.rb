require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user_683) { affair_user(638) }
    let(:user_545) { affair_user(545) }

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }

    def create_overtime_file(start_at, end_at)
      name = unique_id
      workflow_comment = unique_id
      approve_comment = unique_id

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
          within "#ajax-box" do
            click_on "保存"
          end
        end
        expect(page).to have_css('#notice', text: "保存しました。")

        # edit results
        login_user(user_683)
        visit index_path
        click_on name
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
      end

      Gws::Affair::OvertimeFile.find_by(overtime_name: name)
    end

    it "#new" do
      # 2021/1/4 (月) 勤務日 17:00 - 20:00
      start_at = Time.zone.parse("2021/1/4 17:00")
      end_at = Time.zone.parse("2021/1/4 18:00")
      item1 = create_overtime_file(start_at, end_at)

      # 2021/1/8 (金) 勤務日 21:00 - 6:00
      start_at = Time.zone.parse("2021/1/8 21:00")
      end_at = Time.zone.parse("2021/01/9 6:00")
      item2 = create_overtime_file(start_at, end_at)
    end
  end
end
