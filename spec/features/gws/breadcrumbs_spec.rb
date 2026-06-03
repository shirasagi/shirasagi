require 'spec_helper'

#
# グループウェアのメニュー配下で、パンくずに親階層 (スケジュール / リマインダー /
# 出退勤 / 庶務事務 / 業務見える化 / ワークフロー2 / 電子会議室 / 共有アドレス帳 /
# 個人アドレス帳 / 電子職員録 / 操作履歴 / ジョブ) が表示されることを
# feature レベルで保証する。
#
# I18n.t をその場で評価すると spec ロード時点の locale (= 既定値) で固定されてしまい、
# テスト実行時に user の lang から決まる locale (ja/en ランダム) と食い違うため、
# ラベルは Proc に包んで example 実行時に解決する。
#
describe "gws breadcrumbs", type: :feature, dbscope: :example do
  let!(:site) { gws_site }

  before { login_gws_user }

  shared_examples "crumbs contain" do |labels_proc|
    it "shows the expected labels in the breadcrumb" do
      visit visit_path

      within "#crumbs" do
        labels_proc.call.each { |label| expect(page).to have_content(label) }
      end
    end
  end

  shared_examples "linked crumb" do |label_proc, path_method|
    it "shows the parent crumb as a link to its main path" do
      visit visit_path

      within "#crumbs" do
        crumb = find_link(label_proc.call, match: :first)
        expect(crumb[:href]).to end_with(send(path_method, site: site.id))
      end
    end
  end

  context "スケジュール" do
    context "ゴミ箱" do
      let(:visit_path) { gws_schedule_trashes_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/schedule"), I18n.t("gws/schedule.navi.trash")] }
      include_examples "linked crumb",
                       -> { I18n.t("modules.gws/schedule") }, :gws_schedule_main_path
    end
  end

  context "リマインダー" do
    context "未来日のみ" do
      let(:visit_path) { gws_reminder_items_path(site: site, mode: 'future') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("mongoid.models.gws/reminder"),
                           I18n.t("gws/portal.options.reminder_filter.future")
                         ]
                       }
    end

    context "すべて表示" do
      let(:visit_path) { gws_reminder_items_path(site: site, mode: 'all') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("mongoid.models.gws/reminder"),
                           I18n.t("gws/portal.options.reminder_filter.all")
                         ]
                       }
    end
  end

  context "出退勤" do
    context "タイムカード" do
      let(:visit_path) { gws_attendance_main_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/attendance"), I18n.t("modules.gws/attendance/time_card")] }
      include_examples "linked crumb",
                       -> { I18n.t("modules.gws/attendance") }, :gws_attendance_main_path
    end
  end

  context "庶務事務" do
    context "休暇申請 - 休暇取得累計" do
      let(:visit_path) { gws_affair_leave_details_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/leave"),
                           I18n.t("modules.gws/affair/leave/detail")
                         ]
                       }
    end

    context "休暇申請 - 原資区分 (休暇累計)" do
      let!(:cur_year) { create(:gws_affair_capital_year, cur_site: site) }
      let(:visit_path) { gws_affair_capitals_path(site: site, year: cur_year.id) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/leave"),
                           I18n.t("modules.gws/affair/capital")
                         ]
                       }
    end

    context "勤務時間集計 - 職員別" do
      let(:visit_path) { gws_affair_worktime_aggregate_path(site: site, duty_type: 'default') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/worktime/aggregate"),
                           I18n.t("modules.gws/affair/worktime/aggregate/default")
                         ]
                       }
    end

    context "タイムカード - 勤務時間" do
      let(:visit_path) { gws_affair_duty_setting_duty_hours_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/duty_calendar"),
                           I18n.t("modules.gws/affair/duty_hour")
                         ]
                       }
    end

    context "タイムカード - 休日" do
      let(:visit_path) { gws_affair_duty_setting_holiday_calendars_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/duty_calendar"),
                           I18n.t("modules.gws/affair/holiday_calendar")
                         ]
                       }
    end

    context "タイムカード - 警告" do
      let(:visit_path) { gws_affair_duty_setting_duty_notices_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/affair"),
                           I18n.t("modules.gws/affair/duty_calendar"),
                           I18n.t("modules.gws/affair/duty_notice")
                         ]
                       }
    end
  end

  context "照会・回答" do
    context "ゴミ箱" do
      let(:visit_path) { gws_monitor_management_trashes_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/monitor"), I18n.t("ss.navi.trash")] }
    end
  end

  context "業務見える化" do
    context "ゴミ箱" do
      let(:visit_path) { gws_workload_trashes_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/workload"), I18n.t("gws/workload.tabs.trash")] }

      it "does not show a category crumb between 業務見える化 and ゴミ箱" do
        visit visit_path

        within "#crumbs" do
          # 「全業務」のようなカテゴリ名がパンくずに混ざらないこと
          expect(page).to have_no_content(I18n.t("gws/workload.tabs.admin"))
        end
      end
    end
  end

  context "ワークフロー2" do
    context "新規申請 - キーワード検索" do
      let(:visit_path) { gws_workflow2_select_forms_path(site: site, state: 'all', mode: 'by_keyword') }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/workflow2"), I18n.t("gws/workflow2.navi.find_by_keyword")] }
    end

    context "新規申請 - 業務内容で探す" do
      let(:visit_path) { gws_workflow2_select_forms_path(site: site, state: 'all', mode: 'by_purpose') }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/workflow2"), I18n.t("gws/workflow2.navi.find_by_purpose")] }
    end

    context "全申請データ一覧" do
      let(:visit_path) { gws_workflow2_files_path(site: site, state: 'all') }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/workflow2"), I18n.t("gws/workflow2.navi.readable")] }
    end

    context "全申請データ一覧 - 承認依頼されているもの" do
      let(:visit_path) { gws_workflow2_files_path(site: site, state: 'approve') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/workflow2"),
                           I18n.t("gws/workflow2.navi.readable"),
                           I18n.t("gws/workflow2.navi.approve")
                         ]
                       }
    end

    context "全申請データ一覧 - 承認依頼したもの" do
      let(:visit_path) { gws_workflow2_files_path(site: site, state: 'request') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/workflow2"),
                           I18n.t("gws/workflow2.navi.readable"),
                           I18n.t("gws/workflow2.navi.request")
                         ]
                       }
    end

    context "全申請データ一覧 - 回覧中のもの" do
      let(:visit_path) { gws_workflow2_files_path(site: site, state: 'circulation') }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("modules.gws/workflow2"),
                           I18n.t("gws/workflow2.navi.readable"),
                           I18n.t("gws/workflow2.navi.circulation")
                         ]
                       }
    end

    context "提出済・対応待ち一覧" do
      let(:visit_path) { gws_workflow2_files_path(site: site, state: 'destination') }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/workflow2"), I18n.t("gws/workflow2.navi.destination")] }
    end
  end

  context "電子会議室" do
    context "管理一覧" do
      let(:visit_path) { gws_discussion_forums_path(site: site, mode: 'editable') }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/discussion"), I18n.t("ss.navi.editable")] }
    end
  end

  context "共有アドレス帳" do
    context "アドレス設定" do
      let(:visit_path) { gws_shared_address_management_addresses_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/shared_address"), I18n.t("gws/shared_address.navi.address")] }
    end

    context "ゴミ箱 (アドレス設定)" do
      let(:visit_path) { gws_shared_address_management_trashes_path(site: site) }
      it "shows ゴミ箱(アドレス設定) as the leaf crumb" do
        visit visit_path

        within "#crumbs" do
          expect(page).to have_content(I18n.t("modules.gws/shared_address"))
          expected_leaf = "#{I18n.t('ss.links.trash')}(#{I18n.t('gws/shared_address.navi.address')})"
          expect(page).to have_content(expected_leaf)
        end
      end
    end

    context "グループ設定" do
      let(:visit_path) { gws_shared_address_management_groups_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/shared_address"), I18n.t("gws/shared_address.navi.group")] }
    end
  end

  context "個人アドレス帳" do
    context "グループ設定" do
      let(:visit_path) { gws_personal_address_management_groups_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/personal_address"), I18n.t("gws/personal_address.navi.group")] }
    end
  end

  context "電子職員録" do
    let!(:cur_year) { create(:gws_staff_record_year, cur_site: site) }

    context "電子事務分掌表" do
      let(:visit_path) { gws_staff_record_users_path(site: site, year: cur_year.id) }
      include_examples "crumbs contain", -> { [I18n.t("gws/staff_record.staff_records")] }
    end

    context "座席表" do
      let(:visit_path) { gws_staff_record_seatings_path(site: site, year: cur_year.id) }
      include_examples "crumbs contain", -> { [I18n.t("gws/staff_record.staff_records")] }
    end

    context "電子事務分掌表 (公開)" do
      let(:visit_path) { gws_staff_record_public_duties_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [I18n.t("gws/staff_record.staff_records"), I18n.t("gws/staff_record.divide_duties")]
                       }
    end

    context "座席表 (公開)" do
      let(:visit_path) { gws_staff_record_public_seatings_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [I18n.t("gws/staff_record.staff_records"), I18n.t("mongoid.models.gws/staff_record/seating")]
                       }
    end

    context "年度" do
      let(:visit_path) { gws_staff_record_years_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [I18n.t("gws/staff_record.staff_records"), I18n.t("mongoid.models.gws/staff_record/year")]
                       }
    end
  end

  context "操作履歴" do
    context "操作履歴" do
      let(:visit_path) { gws_daily_histories_path(site: site, ymd: "-") }
      include_examples "crumbs contain", -> { [I18n.t("mongoid.models.gws/history")] }

      it "shows 操作履歴 as both the parent and the leaf crumb" do
        visit visit_path

        within "#crumbs" do
          labels = all("li.breadcrumb-item").map { |li| li.text.strip }
          expect(labels.count { |label| label == I18n.t("mongoid.models.gws/history") }).to eq 2
        end
      end
    end

    context "アーカイブ" do
      let(:visit_path) { gws_history_archives_path(site: site) }
      include_examples "crumbs contain",
                       -> {
                         [
                           I18n.t("mongoid.models.gws/history"),
                           I18n.t("mongoid.models.gws/history_archive_file")
                         ]
                       }
    end
  end

  context "ジョブ" do
    context "実行履歴" do
      let(:visit_path) { gws_job_user_logs_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/job"), I18n.t("gws/job.log")] }
    end

    context "実行予約" do
      let(:visit_path) { gws_job_user_reservations_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/job"), I18n.t("gws/job.reservation")] }
    end
  end

  context "ジョブ (設定)" do
    context "実行履歴" do
      let(:visit_path) { gws_job_logs_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/job"), I18n.t("gws/job.log")] }
    end

    context "実行予約" do
      let(:visit_path) { gws_job_reservations_path(site: site) }
      include_examples "crumbs contain",
                       -> { [I18n.t("modules.gws/job"), I18n.t("gws/job.reservation")] }
    end
  end
end
