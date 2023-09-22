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

    def approve_file(item)
      start_at = item.start_at
      approve_comment = unique_id

      Timecop.freeze(start_at) do
        login_user(user545)
        visit index_path
        click_on item.name

        within ".mod-workflow-approve" do
          fill_in "remand[comment]", with: approve_comment
          click_on I18n.t("workflow.buttons.approve")
        end
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
      end
      item.reload
      item
    end

    def edit_results(item)
      start_at = item.start_at

      Timecop.freeze(start_at) do
        login_user(user638)
        visit index_path
        click_on item.name
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
        within "#addon-gws-agents-addons-affair-overtime_result" do
          wait_for_js_ready
          page.accept_confirm do
            click_on I18n.t("gws/affair.links.close_results")
          end
        end
        wait_for_notice I18n.t("gws/affair.notice.close_results")
        wait_for_js_ready
      end
      item.reload
      item
    end

    it "#new" do
      # 2021/1/4 (月) 勤務日 17:00 - 20:00
      start_at = Time.zone.parse("2021/1/4 17:00")
      end_at = Time.zone.parse("2021/1/4 18:00")
      item1 = create_overtime_file(start_at, end_at)
      item1 = request_file(item1)
      item1 = approve_file(item1)
      item1 = input_results(item1)
      item1 = edit_results(item1)
      item1 = close_results(item1)

      # 2021/1/8 (金) 勤務日 21:00 - 6:00
      start_at = Time.zone.parse("2021/1/8 21:00")
      end_at = Time.zone.parse("2021/01/9 6:00")
      item2 = create_overtime_file(start_at, end_at)
      item2 = request_file(item2)
      item2 = approve_file(item2)
      item2 = input_results(item2)
      item2 = edit_results(item2)
      item2 = close_results(item2)
    end
  end
end
