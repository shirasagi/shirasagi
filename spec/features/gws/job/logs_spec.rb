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
      ::FileUtils.mkdir_p(::File.dirname(log.file_path)) rescue nil
      ::File.open(log.file_path, 'wt') do |f|
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
      expect(page).to have_content(log1.started.strftime("%Y/%m/%d %H:%M"))
      expect(page).to have_content(log1.logs.first.strip)

      visit gws_job_logs_path(site: site)
      click_on I18n.t(log2.class_name.underscore, scope: "job.models")
      expect(page).to have_content(I18n.t(log2.state, scope: "job.state"))
      expect(page).to have_content(log2.started.strftime("%Y/%m/%d %H:%M"))
      expect(page).to have_content(log2.closed.strftime("%Y/%m/%d %H:%M"))
      expect(page).to have_content(log2.logs.first.strip)

      visit gws_job_logs_path(site: site)
      click_on I18n.t(log3.class_name.underscore, scope: "job.models")
      expect(page).to have_content(I18n.t(log3.state, scope: "job.state"))
      expect(page).to have_content(log3.started.strftime("%Y/%m/%d %H:%M"))
      expect(page).to have_content(log3.closed.strftime("%Y/%m/%d %H:%M"))
      expect(page).to have_content(log3.logs.first.strip)
    end
  end
end
