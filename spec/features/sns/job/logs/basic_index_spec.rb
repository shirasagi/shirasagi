require 'spec_helper'

describe "sns_job_logs", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user1) { create :sys_user_sample }
  let(:user2) { create :sys_user_sample }
  let(:now) { Time.zone.now.beginning_of_minute }
  let!(:log1) do
    Timecop.freeze(now.ago(3.days)) do
      job1 = Gws::Schedule::TrashPurgeJob.new.bind("site_id" => site.id, "user_id" => user1.id)
      create(:gws_job_log, :gws_job_log_running, job: job1)
    end
  end
  let!(:log2) do
    Timecop.freeze(now.ago(1.day)) do
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
        visit job_sns_logs_path(site: site)

        expect(page).to have_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
        expect(page).to have_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(log1.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log1.state, scope: "job.state"))
        expect(page).to have_content(I18n.l(log1.started, format: :picker))
        expect(page).to have_content(log1.logs.first.strip)

        visit job_sns_logs_path(site: site)
        click_on I18n.t(log2.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log2.state, scope: "job.state"))
        expect(page).to have_content(I18n.l(log2.started, format: :picker))
        expect(page).to have_content(I18n.l(log2.closed, format: :picker))
        expect(page).to have_content(log2.logs.first.strip)
      end
    end

    context "with user2" do
      it do
        login_user user2
        visit job_sns_logs_path(site: site)

        expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
        expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
        expect(page).to have_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

        click_on I18n.t(log3.class_name.underscore, scope: "job.models")
        expect(page).to have_content(I18n.t(log3.state, scope: "job.state"))
        expect(page).to have_content(I18n.l(log3.started, format: :picker))
        expect(page).to have_content(log3.logs.first.strip)
      end
    end
  end
end
