require 'spec_helper'

describe Gws::Reminder::NotificationJob, dbscope: :example do
  let(:site) { gws_site }
  let(:reminder_condition) do
    { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
  end
  let(:schedule) do
    create(
      :gws_schedule_plan,
      start_at: 1.hour.from_now.strftime('%Y/%m/%d %H:%M'), end_at: 2.hours.from_now.strftime('%Y/%m/%d %H:%M'),
      in_reminder_conditions: [ reminder_condition ])
  end
  let(:reminder) { schedule.reminder(gws_user) }
  let(:default_from) { SS.config.mail.default_from }
  let(:sender_email) { "sys@example.jp" }

  before do
    ActionMailer::Base.deliveries = []
  end

  after do
    ActionMailer::Base.deliveries = []
  end

  context 'usual case' do
    it do
      expect(reminder.notifications).to be_present
      Timecop.travel(reminder.notifications.first.notify_at) do
        described_class.bind(site_id: site.id).perform_now
      end

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(include("リマインダー通知（メール送信）"))
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq default_from
        expect(notify_mail.to.first).to eq reminder.user.email
        expect(notify_mail.subject).to eq "[リマインダー] スケジュール - #{schedule.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("[タイトル] #{schedule.name}")
        expect(notify_mail.body.raw_source).to include("[日時] #{I18n.l(schedule.start_at.to_date, format: :gws_long)}")
        expect(notify_mail.body.raw_source).to include("[参加ユーザー]\n")
        expect(notify_mail.body.raw_source).to include(schedule.members.first.long_name)
      end
    end

    it 'use notice (internal message)' do
      reminder.notifications.first.update(state: 'enabled')

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
    end
  end

  context 'send notification twice' do
    it do
      Timecop.travel(reminder.notifications.first.notify_at) do
        described_class.bind(site_id: site.id).perform_now
        described_class.bind(site_id: site.id).perform_now
      end

      # delivered only one mail
      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq default_from
        expect(notify_mail.to.first).to eq reminder.user.email
        expect(notify_mail.subject).to eq "[リマインダー] スケジュール - #{schedule.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("[タイトル] #{schedule.name}")
        expect(notify_mail.body.raw_source).to include("[日時] #{I18n.l(schedule.start_at.to_date, format: :gws_long)}")
        expect(notify_mail.body.raw_source).to include("[参加ユーザー]\n")
        expect(notify_mail.body.raw_source).to include(schedule.members.first.long_name)
      end

      expect(Gws::Job::Log.count).to eq 2
      Gws::Job::Log.all.each do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end
    end
  end

  context 'modify notify_mail from' do
    before do
      s = gws_site
      s.sender_email = sender_email
      s.save!
    end

    it do
      expect(reminder.notifications).to be_present
      Timecop.travel(reminder.notifications.first.notify_at) do
        described_class.bind(site_id: site.id).perform_now
      end

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq sender_email
        expect(notify_mail.to.first).to eq reminder.user.email
        expect(notify_mail.subject).to eq "[リマインダー] スケジュール - #{schedule.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("[タイトル] #{schedule.name}")
        expect(notify_mail.body.raw_source).to include("[日時] #{I18n.l(schedule.start_at.to_date, format: :gws_long)}")
        expect(notify_mail.body.raw_source).to include("[参加ユーザー]\n")
        expect(notify_mail.body.raw_source).to include(schedule.members.first.long_name)
      end
    end
  end

  context 'with from/to options' do
    it do
      expect(reminder.notifications).to be_present
      from = reminder.notifications.first.notify_at.iso8601
      to = (reminder.notifications.first.notify_at + 1.second).iso8601
      described_class.bind(site_id: site.id).perform_now(from: from, to: to)

      expect(Gws::Job::Log.count).to eq 1
      Gws::Job::Log.first.tap do |log|
        expect(log.logs).to include(/INFO -- : .* Started Job/)
        expect(log.logs).to include(/INFO -- : .* Completed Job/)
        expect(log.logs).to include(include("リマインダー通知（メール送信）"))
      end

      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |notify_mail|
        expect(notify_mail.from.first).to eq default_from
        expect(notify_mail.to.first).to eq reminder.user.email
        expect(notify_mail.subject).to eq "[リマインダー] スケジュール - #{schedule.name}"
        expect(notify_mail.body.multipart?).to be_falsey
        expect(notify_mail.body.raw_source).to include("[タイトル] #{schedule.name}")
        expect(notify_mail.body.raw_source).to include("[日時] #{I18n.l(schedule.start_at.to_date, format: :gws_long)}")
        expect(notify_mail.body.raw_source).to include("[参加ユーザー]\n")
        expect(notify_mail.body.raw_source).to include(schedule.members.first.long_name)
      end
    end
  end
end
