require 'spec_helper'
require "csv"

describe "gws_job_logs", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:log1) do
    Timecop.freeze(now.ago(3.days)) do
      job1 = Gws::Schedule::TrashPurgeJob.new.bind("site_id" => site.id, "user_id" => user.id)
      create(:gws_job_log, :gws_job_log_running, job: job1)
    end
  end
  let!(:log2) do
    Timecop.freeze(now.ago(1.day)) do
      job2 = Gws::Notice::NotificationJob.new.bind("site_id" => site.id, "user_id" => user.id)
      create(:gws_job_log, :gws_job_log_completed, job: job2)
    end
  end
  let!(:log3) do
    Timecop.freeze(now.ago(3.hours)) do
      job3 = Gws::Reminder::NotificationJob.new.bind("site_id" => site.id, "user_id" => user.id)
      create(:gws_job_log, :gws_job_log_failed, job: job3)
    end
  end
  let!(:logs) { [log1, log2, log3] }

  before do
    logs.each do |log|
      FileUtils.mkdir_p(File.dirname(log.file_path)) rescue nil
      File.open(log.file_path, 'wt') do |f|
        f.puts unique_id
      end
    end

    login_gws_user
  end

  context "with basic crud" do
    it do
      visit gws_job_logs_path(site: site)

      expect(page).to have_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      click_on I18n.t(log1.class_name.underscore, scope: "job.models")
      expect(page).to have_content(I18n.t(log1.state, scope: "job.state"))
      expect(page).to have_content(I18n.l(log1.started, format: :picker))
      expect(page).to have_content(log1.logs.first.strip)

      visit gws_job_logs_path(site: site)
      click_on I18n.t(log2.class_name.underscore, scope: "job.models")
      expect(page).to have_content(I18n.t(log2.state, scope: "job.state"))
      expect(page).to have_content(I18n.l(log2.started, format: :picker))
      expect(page).to have_content(I18n.l(log2.closed, format: :picker))
      expect(page).to have_content(log2.logs.first.strip)

      visit gws_job_logs_path(site: site)
      click_on I18n.t(log3.class_name.underscore, scope: "job.models")
      expect(page).to have_content(I18n.t(log3.state, scope: "job.state"))
      expect(page).to have_content(I18n.l(log3.started, format: :picker))
      expect(page).to have_content(I18n.l(log3.closed, format: :picker))
      expect(page).to have_content(log3.logs.first.strip)
    end
  end

  context "download all" do
    it do
      visit gws_job_logs_path(site: site)
      within ".nav-menu" do
        click_on I18n.t("ss.links.download")
      end
      within "form#item-form" do
        click_on I18n.t("ss.buttons.download")
      end

      wait_for_download

      I18n.with_locale(I18n.default_locale) do
        SS::Csv.open(downloads.first) do |csv|
          csv_table = csv.read
          expect(csv_table.length).to eq 1
          expect(csv_table.headers).to include(*%w(ClassName Started Closed State Args Logs))
          csv_table[0].tap do |row|
            expect(row["ClassName"]).to eq I18n.t(log3.class_name.underscore, scope: "job.models")
            expect(row["Started"]).to eq log3.start_label
            expect(row["Closed"]).to eq log3.closed_label
            expect(row["State"]).to eq I18n.t(log3.state, scope: "job.state")
            expect(row["Args"]).to be_blank
            expect(row["Logs"]).to be_present
          end
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/job/logs"
        expect(history.path).to eq download_all_gws_job_logs_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end
end
