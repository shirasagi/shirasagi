require 'spec_helper'

describe Gws::Reminder::NotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:reminder_condition) do
    { 'user_id' => user.id, 'state' => 'enabled', 'interval' => 10, 'interval_type' => 'minutes' }
  end
  let(:schedule) do
    create(
      :gws_schedule_plan,
      cur_user: user,
      start_at: 1.hour.from_now.strftime('%Y/%m/%d %H:%M'), end_at: 2.hours.from_now.strftime('%Y/%m/%d %H:%M'),
      member_ids: [user.id],
      in_reminder_conditions: [ reminder_condition ])
  end
  let(:reminder) { schedule.reminder(user) }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context 'user email exists' do
    let!(:user) { create :gws_user, group_ids: gws_user.group_ids }

    it do
      expect(reminder.notifications).to be_present
      Timecop.travel(reminder.notifications.first.notify_at) do
        described_class.bind(site_id: site.id).perform_now
      end

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(include("リマインダー通知"))
      end
      expect(ActionMailer::Base.deliveries.length).to eq 0

      expect(SS::Notification.user(user).count).to eq 1
      notification = SS::Notification.user(user).first

      expect(notification.text).to include("[タイトル] #{schedule.name}")
      expect(notification.text).to include(user.long_name)
    end
  end

  context 'user email not exists' do
    let!(:user) { create :gws_user, email: nil, group_ids: gws_user.group_ids }

    it do
      expect(reminder.notifications).to be_present
      Timecop.travel(reminder.notifications.first.notify_at) do
        described_class.bind(site_id: site.id).perform_now
      end

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(include("リマインダー通知"))
      end
      expect(ActionMailer::Base.deliveries.length).to eq 0

      expect(SS::Notification.user(user).count).to eq 1
      notification = SS::Notification.user(user).first
      expect(notification.text).to include("[タイトル] #{schedule.name}")
      expect(notification.text).to include(user.long_name)
    end
  end
end
