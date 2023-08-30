require 'spec_helper'

describe "gws_affair_overtime_files", type: :feature, dbscope: :example, js: true do
  context "basic crud" do
    before { create_affair_users }

    let(:site) { affair_site }
    let(:user638) { affair_user(638) } #部課長
    let(:user545) { affair_user(545) } #人事担当

    let(:new_path) { new_gws_affair_overtime_file_path(site: site, state: "mine") }
    let(:index_path) { gws_affair_overtime_files_path(site: site, state: "all") }
    let(:approve_path) { gws_affair_overtime_files_path(site: site, state: "approve") }

    def create_overtime_file(start_at, end_at)
      name = unique_id

      Timecop.freeze(start_at) do
        login_user(user638)
        visit new_path

        within "form#item-form" do
          expect(page).to have_css(".selected-capital", text: user638.effective_capital(site).name)
          fill_in "item[overtime_name]", with: name

          fill_in "item[start_at_date]", with: start_at.to_date
          select I18n.t('gws/attendance.hour', count: start_at.hour), from: 'item[start_at_hour]'
          select I18n.t('gws/attendance.minute', count: start_at.min), from: 'item[start_at_minute]'

          fill_in "item[end_at_date]", with: end_at.to_date
          select I18n.t('gws/attendance.hour', count: end_at.hour), from: 'item[end_at_hour]'
          select I18n.t('gws/attendance.minute', count: end_at.min), from: 'item[end_at_minute]'

          click_on I18n.t("ss.buttons.save")
        end
        wait_for_notice I18n.t("ss.notice.saved")
        wait_for_js_ready
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
        wait_for_js_ready
        expect(page).to have_css("#workflow_route", text: I18n.t("mongoid.attributes.workflow/model/route.my_group"))

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
        within "#addon-basic" do
          expect(page).to have_css("dd", text: I18n.t("gws/affair.options.status.request"))
        end
      end
      item.reload
      item
    end

    it "#approve_all" do
      # 2021/1/4 (月) 勤務日 17:00 - 20:00
      start_at = Time.zone.parse("2021/1/4 17:00")
      end_at = Time.zone.parse("2021/1/4 18:00")
      item = create_overtime_file(start_at, end_at)
      item = request_file(item)

      Timecop.freeze(start_at) do
        login_user(user545)
        visit approve_path

        within ".list-items" do
          expect(page).to have_link item.name
        end

        wait_event_to_fire("ss:checked-all-list-items") { find('.list-head input[type="checkbox"]').set(true) }
        within ".list-head" do
          page.accept_alert do
            click_button I18n.t('ss.links.approve')
          end
        end
        wait_for_notice I18n.t("ss.notice.approved")

        visit approve_path
        within ".list-items" do
          expect(page).to have_no_link item.name
        end

        visit index_path
        within ".list-items" do
          expect(page).to have_link item.name
          click_on item.name
        end

        within "#addon-basic" do
          expect(page).to have_css("dd", text: I18n.t("gws/affair.options.overtime_status.approve"))
        end
      end
    end
  end
end
