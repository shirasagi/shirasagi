require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "reminder of schedule", js: true do
    let(:site) { gws_site }
    let(:reminder_condition) do
      { 'user_id' => gws_user.id, 'state' => 'mail', 'interval' => 10, 'interval_type' => 'minutes' }
    end
    let(:plan) do
      create(
        :gws_schedule_plan,
        start_at: 1.hour.from_now.strftime('%Y/%m/%d %H:%M'),
        end_at: 2.hours.from_now.strftime('%Y/%m/%d %H:%M'),
        in_reminder_conditions: [ reminder_condition ]
      )
    end
    let(:show_path) { gws_schedule_plan_path site, plan }

    before { login_gws_user }

    it do
      #
      # 既定ではリマインダーが 1 件登録されているはずなので、確認する
      #
      visit show_path
      expect(Gws::Reminder.count).to eq 1
      within ".gws-addon-reminder" do
        within first('.remider-conditions tr') do
          expect(page).to have_select("item[in_reminder_conditions][][state]", selected: I18n.t('gws/reminder.options.notify_state.mail'))
        end
      end

      #
      # リマインダーを解除
      #
      within ".gws-addon-reminder" do
        within first('.remider-conditions tr') do
          find('button.action-remove').click
        end
        click_on I18n.t('gws/reminder.buttons.register_reminder')
      end

      # 解除できたか確認
      # リマインダーは非同期で解除される。
      expect(page).to have_css('#notice', text: I18n.t('gws/reminder.notification.created'))

      # 解除できたら、ドキュメントは存在しないはず
      expect(Gws::Reminder.count).to eq 0

      #
      # リマインダーをもう一度登録する
      #
      within ".gws-addon-reminder" do
        within first('.remider-conditions tr') do
          select I18n.t('gws/reminder.options.notify_state.mail'), from: 'item[in_reminder_conditions][][state]'
        end
        click_on I18n.t('gws/reminder.buttons.register_reminder')
      end

      # 登録できたか確認
      # リマインダーは非同期で登録される。
      # capybara は element が存在しない場合、しばらく待機するので、以下の確認は登録を待機する意味もある
      expect(page).to have_css('#notice', text: I18n.t('gws/reminder.notification.created'))

      expect(Gws::Reminder.count).to eq 1
    end
  end
end
