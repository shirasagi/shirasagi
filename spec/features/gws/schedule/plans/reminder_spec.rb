require 'spec_helper'

describe "gws_schedule_plans", type: :feature, dbscope: :example do
  context "reminder of schedule", js: true do
    let(:site) { gws_site }
    let(:plan) { create :gws_schedule_plan }
    let(:show_path) { gws_schedule_plan_path site, plan }

    before { login_gws_user }

    it do
      #
      # 既定ではリマインダーが 1 件登録されているはずなので、確認する
      #
      visit show_path
      expect(Gws::Reminder.count).to eq 1
      within "div.gws-addon-reminder" do
        expect(page).to have_css(".gws-addon-reminder-label", text: I18n.t("gws.reminder.states.entry"))
      end

      #
      # リマインダーを解除
      #
      within "div.gws-addon-reminder" do
        click_button "解除"
      end

      # 解除できたか確認
      # リマインダーは非同期で解除される。
      # capybara は element が存在しない場合、しばらく待機するので、以下の確認は解除を待機する意味もある
      within "div.gws-addon-reminder" do
        expect(page).to have_css(".gws-addon-reminder-label", text: I18n.t("gws.reminder.states.empty"))
      end

      # 解除できたら、ドキュメントは存在しないはず
      expect(Gws::Reminder.count).to eq 0

      #
      # リマインダーをもう一度登録する
      #
      within "div.gws-addon-reminder" do
        click_button "登録"
      end

      # 登録できたか確認
      # リマインダーは非同期で登録される。
      # capybara は element が存在しない場合、しばらく待機するので、以下の確認は登録を待機する意味もある
      within "div.gws-addon-reminder" do
        expect(page).to have_css(".gws-addon-reminder-label", text: I18n.t("gws.reminder.states.entry"))
      end

      expect(Gws::Reminder.count).to eq 1
    end
  end
end
