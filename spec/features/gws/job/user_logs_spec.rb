require 'spec_helper'

describe "gws_job_user_logs", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let(:user2) { create :gws_user, group_ids: gws_user.group_ids, gws_role_ids: gws_user.gws_role_ids }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:log1) do
    Timecop.freeze(now.ago(8.days)) do
      job1 = Gws::Schedule::TrashPurgeJob.new.bind("site_id" => site.id, "user_id" => user1.id)
      create(:gws_job_log, :gws_job_log_running, job: job1)
    end
  end
  let!(:log2) do
    Timecop.freeze(now.ago(3.days)) do
      job2 = Gws::Notice::NotificationJob.new.bind("site_id" => site.id, "user_id" => user1.id)
      create(:gws_job_log, :gws_job_log_completed, job: job2)
    end
  end
  let!(:log3) do
    Timecop.freeze(now.ago(3.hours)) do
      job3 = Gws::Reminder::NotificationJob.new.bind("site_id" => site.id, "user_id" => user2.id)
      create(:gws_job_log, :gws_job_log_failed, job: job3)
    end
  end
  let!(:logs) { [log1, log2, log3] }

  before do
    logs.each do |log|
      ::FileUtils.mkdir_p(::File.dirname(log.file_path)) rescue nil
      ::File.open(log.file_path, 'wt') do |f|
        f.puts unique_id
      end
    end
  end

  context "basic index" do
    context "with user1" do
      it do
        login_user user1
        visit gws_job_user_logs_path(site: site)

        expect(page).to have_css(".list-item .title", text: I18n.t(log1.class_name.underscore, scope: "job.models"))
        expect(page).to have_css(".list-item .title", text: I18n.t(log2.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(log1.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log1.state, scope: "job.state"))
        expect(page).to have_content(log1.started.strftime("%Y/%m/%d %H:%M"))
        expect(page).to have_content(log1.logs.first.strip)

        visit gws_job_user_logs_path(site: site)
        click_on I18n.t(log2.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log2.state, scope: "job.state"))
        expect(page).to have_content(log2.started.strftime("%Y/%m/%d %H:%M"))
        expect(page).to have_content(log2.closed.strftime("%Y/%m/%d %H:%M"))
        expect(page).to have_content(log2.logs.first.strip)
      end
    end

    context "with user2" do
      it do
        login_user user2
        visit gws_job_user_logs_path(site: site)

        expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
        expect(page).to have_css(".list-item .title", text: I18n.t(log3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(log3.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log3.state, scope: "job.state"))
        expect(page).to have_content(log3.started.strftime("%Y/%m/%d %H:%M"))
        expect(page).to have_content(log3.logs.first.strip)
      end
    end
  end

  describe "download" do
    before { clear_downloads }
    after { clear_downloads }

    it do
      login_user user1
      visit gws_job_user_logs_path(site: site)
      click_on I18n.t("ss.links.download")

      within "form" do
        select I18n.t("ss.options.duration.1_year"), from: "item[save_term]"
        click_on I18n.t("ss.buttons.download")
      end
      wait_for_download

      SS::Csv.open(downloads.first) do |csv|
        csv_table = csv.read
        expect(csv_table.length).to eq 2
        expect(csv_table.headers).to include(*%w(ClassName Started Closed State Args Logs))
        csv_table[0].tap do |row|
          expect(row["ClassName"]).to eq I18n.t(log1.class_name.underscore, scope: "job.models")
          expect(row["Started"]).to eq log1.start_label
          expect(row["Closed"]).to be_blank
          expect(row["State"]).to eq I18n.t(log1.state, scope: "job.state")
          expect(row["Args"]).to be_blank
          expect(row["Logs"]).to be_present
        end
        csv_table[1].tap do |row|
          expect(row["ClassName"]).to eq I18n.t(log2.class_name.underscore, scope: "job.models")
          expect(row["Started"]).to eq log2.start_label
          expect(row["Closed"]).to eq log2.closed_label
          expect(row["State"]).to eq I18n.t(log2.state, scope: "job.state")
          expect(row["Args"]).to be_blank
          expect(row["Logs"]).to be_present
        end
      end

      expect(Gws::History.all.count).to be > 1
      Gws::History.all.reorder(created: -1).first.tap do |history|
        expect(history.severity).to eq "info"
        expect(history.controller).to eq "gws/job/user_logs"
        expect(history.path).to eq download_all_gws_job_user_logs_path(site: site)
        expect(history.action).to eq "download_all"
      end
    end
  end

  describe "batch destroy" do
    it do
      login_user user1
      visit gws_job_user_logs_path(site: site)
      click_on I18n.t("ss.links.delete")

      within "form" do
        select I18n.t("ss.options.duration.1_week"), from: "item[save_term]"
        click_on I18n.t("ss.buttons.delete")
      end
      wait_for_notice I18n.t("ss.notice.deleted")

      expect { log1.reload }.to raise_error Mongoid::Errors::DocumentNotFound
      expect { log2.reload }.not_to raise_error
      expect { log3.reload }.not_to raise_error
    end
  end
end
