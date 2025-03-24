require 'spec_helper'

describe "sns_job_logs", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:user) { gws_user }
  let(:now) { Time.zone.now.change(hour: 9).beginning_of_minute }
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
  end

  context "move with buttons" do
    it do
      login_user user
      visit job_sns_logs_path(site: site)
      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.today')
        end
      end

      expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.prev_day')
        end
      end

      expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.prev_day')
        end
      end

      expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.prev_day')
        end
      end

      expect(page).to have_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.prev_day')
        end
      end

      expect(page).to have_no_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          click_on I18n.t('gws.history.days.next_day')
        end
      end

      expect(page).to have_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))
    end
  end

  context "move with directly inputting date value" do
    it do
      login_user user
      visit job_sns_logs_path(site: site)

      wait_for_event_fired "turbo:frame-load" do
        within ".list-head" do
          fill_in_date "ymd", with: now.ago(3.days)
        end
      end

      expect(page).to have_content(I18n.t(log1.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log2.class_name.underscore, scope: "job.models"))
      expect(page).to have_no_content(I18n.t(log3.class_name.underscore, scope: "job.models"))
    end
  end
end
