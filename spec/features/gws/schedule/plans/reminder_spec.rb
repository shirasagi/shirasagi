require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example, js: true do
  let(:site) { gws_site }
  let(:plan) do
    create(
      :gws_schedule_plan,
      start_at: 1.hour.from_now.strftime('%Y/%m/%d %H:%M'),
      end_at: 2.hours.from_now.strftime('%Y/%m/%d %H:%M')
    )
  end
  let(:show_path) { gws_schedule_plan_path site, plan }

  before do
    # メール転送を有効にする
    user = gws_user
    user.notice_schedule_user_setting = "notify"
    user.notice_schedule_email_user_setting = "notify"
    user.send_notice_mail_addresses = "#{unique_id}@example.jp"
    user.save!

    login_gws_user
  end

  context "when reminder on schedule plan is cancelled" do
    let(:reminder_condition) do
      { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
    end

    before do
      # リマインダーを保存させるために @db_changes が必要なため、`#name` に別の文字列をセットする。
      plan.name = unique_id
      plan.in_reminder_conditions = [ reminder_condition ]
      plan.save!
    end

    it do
      #
      # リマインダーが 1 件登録されているはずなので、確認する
      #
      visit show_path
      expect(Gws::Reminder.count).to eq 1
      within ".gws-addon-reminder" do
        within first('.reminder-conditions tr') do
          selected = I18n.t('gws/reminder.options.notify_state.mail')
          expect(page).to have_select("item[in_reminder_conditions][][state]", selected: selected)
        end
      end

      #
      # リマインダーを解除
      #
      within ".gws-addon-reminder" do
        within first('.reminder-conditions tr') do
          find('button.action-remove').click
        end
        click_on I18n.t('gws/reminder.buttons.register_reminder')
      end

      # 解除できたか確認
      # リマインダーは非同期で解除される。
      expect(page).to have_css('#notice', text: I18n.t('gws/reminder.notification.created'))

      # 解除できたら、ドキュメントは存在しないはず
      expect(Gws::Reminder.count).to eq 0
    end
  end

  context "when `enabled` is given to reminder state" do
    it do
      #
      # リマインダーを登録する
      #
      visit show_path
      within ".gws-addon-reminder" do
        within first('.reminder-conditions tr') do
          select I18n.t('gws/reminder.options.notify_state.enabled'), from: 'item[in_reminder_conditions][][state]'
        end
        click_on I18n.t('gws/reminder.buttons.register_reminder')
      end

      # 登録できたか確認
      # リマインダーは非同期で登録される。
      # capybara は element が存在しない場合、しばらく待機するので、以下の確認は登録を待機する意味もある
      expect(page).to have_css('#notice', text: I18n.t('gws/reminder.notification.created'))

      expect(Gws::Reminder.count).to eq 1
      reminder = Gws::Reminder.first
      expect(reminder.site_id).to eq plan.site_id
      expect(reminder.date).to eq plan.start_at
      expect(reminder.start_at).to eq plan.start_at
      expect(reminder.end_at).to eq plan.end_at
      expect(reminder.notifications.length).to eq 1
      reminder.notifications.first.tap do |notification|
        expect(notification.state).to eq "enabled"
        expect(notification.interval).to eq 10
        expect(notification.interval_type).to eq "minutes"
        expect(notification.notify_at).to eq plan.start_at - notification.interval.minutes
        expect(notification.base_time).to be_blank
        expect(notification.delivered_at).to eq Time.zone.at(0)
      end

      #
      # リマインド日時まで時を進め、通知送信ジョブを実行する
      #
      Timecop.freeze(reminder.notifications.first.notify_at) do
        Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now
      end
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      reminder.reload
      expect(reminder.notifications.length).to eq 1
      reminder.notifications.first.tap do |notification|
        expect(notification.delivered_at).to eq notification.notify_at
      end

      expect(SS::Notification.all.count).to eq 1
      SS::Notification.all.first.tap do |notice|
        subject = I18n.t(
          "gws/reminder.notification.subject",
          model: I18n.t("mongoid.models.#{reminder.model}"), name: reminder.name
        )
        expect(notice.subject).to eq subject
        expect(notice.member_ids.length).to eq 1
        expect(notice.member_ids).to include(reminder.user_id)
      end

      # スケジュールの通知転送設定を有効にしても、リマインダーには効果なし
      expect(ActionMailer::Base.deliveries.length).to eq 0
    end
  end

  context "when `mail` is given to reminder state" do
    include Gws::Schedule::PlanHelper

    it do
      #
      # リマインダーを登録する
      #
      visit show_path
      within ".gws-addon-reminder" do
        within first('.reminder-conditions tr') do
          select I18n.t('gws/reminder.options.notify_state.mail'), from: 'item[in_reminder_conditions][][state]'
        end
        click_on I18n.t('gws/reminder.buttons.register_reminder')
      end

      # 登録できたか確認
      # リマインダーは非同期で登録される。
      # capybara は element が存在しない場合、しばらく待機するので、以下の確認は登録を待機する意味もある
      expect(page).to have_css('#notice', text: I18n.t('gws/reminder.notification.created'))

      expect(Gws::Reminder.count).to eq 1
      reminder = Gws::Reminder.first
      expect(reminder.site_id).to eq plan.site_id
      expect(reminder.date).to eq plan.start_at
      expect(reminder.start_at).to eq plan.start_at
      expect(reminder.end_at).to eq plan.end_at
      expect(reminder.notifications.length).to eq 1
      reminder.notifications.first.tap do |notification|
        expect(notification.state).to eq "mail"
        expect(notification.interval).to eq 10
        expect(notification.interval_type).to eq "minutes"
        expect(notification.notify_at).to eq plan.start_at - notification.interval.minutes
        expect(notification.base_time).to be_blank
        expect(notification.delivered_at).to eq Time.zone.at(0)
        puts "notification.notify_at=#{notification.notify_at}"
      end

      #
      # リマインド日時まで時を進め、通知送信ジョブを実行する
      #
      Timecop.freeze(reminder.notifications.first.notify_at) do
        Gws::Reminder::NotificationJob.bind(site_id: site.id).perform_now
      end
      Job::Log.first.tap do |log|
        expect(log.logs).to include(include("INFO -- : Started Job"))
        expect(log.logs).to include(include("INFO -- : Completed Job"))
      end

      reminder.reload
      expect(reminder.notifications.length).to eq 1
      reminder.notifications.first.tap do |notification|
        expect(notification.delivered_at).to eq notification.notify_at
      end

      # 通知はされていない
      expect(SS::Notification.all.count).to eq 0

      # メールが送られたはず
      expect(ActionMailer::Base.deliveries.length).to eq 1
      ActionMailer::Base.deliveries.first.tap do |mail|
        subject = I18n.t(
          "gws/reminder.notification.subject",
          model: I18n.t("mongoid.models.#{reminder.model}"), name: reminder.name
        )
        expect(mail.subject).to eq subject
        expect(mail.to.length).to eq 1
        expect(mail.to).to include reminder.user.email
        expect(mail.body.multipart?).to be_falsey
        expect(mail.body.raw_source).to include "[#{reminder.item.class.t :name}] #{reminder.item.name}"
        expect(mail.body.raw_source).to include "[#{reminder.item.class.t :term}] #{term(reminder.item)}"
        expect(mail.body.raw_source).to include reminder.user.long_name
      end
    end
  end
end
